# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Emits the elements layer. Orchestrates per-element rendering
      # by delegating to specialized compartment renderers (shape,
      # header, divider, attribute). Frame-element filtering and
      # stereotype-color fallback also live in dedicated
      # collaborators.
      class Elements
        DEFAULT_FILL = "#FFFFFF"
        DEFAULT_STROKE = "#000000"
        DEFAULT_STROKE_WIDTH = 2
        DEFAULT_TEXT_COLOR = "#000000"

        attr_reader :diagram, :model_index, :canvas, :document

        def initialize(diagram, model_index:, canvas: nil, document: nil)
          @diagram = diagram
          @model_index = model_index
          @canvas = canvas
          @document = document
        end

        def render
          groups.join("\n")
        end

        # Returns an Array of per-entity `<g>...</g>` strings.
        # Each element contributes up to 4 groups (shape, header,
        # divider, attrs) in EA's per-entity layer order.
        def groups
          ordered_elements.flat_map { |e| groups_for(e) }
        end

        private

        def ordered_elements
          (diagram.elements || []).sort_by { |e| e.z_order || 0 }
        end

        def groups_for(element)
          return [] if element_filter.skip?(element)

          context = build_context(element)
          return [] unless context

          Compartment.render_all(context).compact
        end

        # Build the RenderContext for one element. Returns nil when
        # the element has no usable bounds (skip rendering).
        def build_context(element)
          raw_bounds = element.bounds || element.image_bounds
          return nil unless raw_bounds

          bounds = translate_bounds(raw_bounds)
          model_element = model_element_for(element)
          classifier = classifier_for(element)
          size = font_resolver.size_for(element)
          family = font_resolver.family_for(element)
          size_unit = font_resolver.size_unit_for(element)
          parent_name = off_canvas_parent_name_for(classifier)

          header_lines = classifier ? Element::HeaderLines.for(classifier,
                                                                diagram_package_id: diagram.package_id,
                                                                visually_nested: visually_nested?(element),
                                                                umldi_keyword: element.umldi_keyword,
                                                                bounds_width: raw_bounds&.width,
                                                                font_size: size,
                                                                off_canvas_parent_name: parent_name) : []
          is_classifier = classifier.is_a?(Ea::Model::Classifier)
          attr_lines = (is_classifier && show_attributes?) ? Element::AttributeRenderer.lines_for(classifier, lookup: attribute_lookup) : []
          op_lines = (is_classifier && show_operations?) ? Element::OperationRenderer.lines_for(classifier) : []
          geometry = CompartmentGeometry.new(bounds: bounds, size: size,
                                              header_lines_count: header_lines.size,
                                              attr_lines_count: attr_lines.size,
                                              op_lines_count: op_lines.size,
                                              tagged_values_count: tagged_values_for(classifier).size,
                                              header_top_padding: theme.compartments.header_top_padding,
                                              header_line_offset: theme.compartments.header_line_offset,
                                              divider_offset: theme.compartments.divider_offset,
                                              attr_line_offset: theme.compartments.attr_line_offset,
                                              attr_first_offset: theme.compartments.attr_first_offset)
          RenderContext.new(
            element: element,
            bounds: bounds,
            model_element: model_element,
            classifier: classifier,
            fill: resolve_fill(element, classifier),
            stroke: resolve_stroke,
            stroke_width: resolve_stroke_width,
            text_fill: theme.text_color,
            family: family, size: size, size_unit: size_unit,
            header_lines: header_lines,
            attr_lines: attr_lines,
            op_lines: op_lines,
            enum_literals: enum_literals_for(classifier),
            tagged_values: element.show_tagged_values ? tagged_values_for(classifier) : [],
            constraints: constraints_for(classifier),
            package_content_lines: package_content_lines_for(model_element),
            geometry: geometry,
            theme: theme,
            canvas: canvas,
            diagram: diagram,
            model_index: model_index,
            off_canvas_parent_name: parent_name
          )
        end

        def enum_literals_for(classifier)
          return [] unless classifier.is_a?(Ea::Model::Enumeration)

          classifier.literals || []
        end

        def tagged_values_for(classifier)
          return [] unless classifier.is_a?(Ea::Model::Classifier)

          classifier.tagged_values || []
        end

        def constraints_for(classifier)
          return [] unless classifier.is_a?(Ea::Model::Classifier)

          classifier.constraints || []
        end

        # EA renders the off-canvas parent classifier's name as an
        # italic line at the top of a placed element's header when
        # ALL of these hold:
        #
        #   1. The diagram's HideParents flag is 0 (the default).
        #      HideParents=1 suppresses the ghost line entirely.
        #   2. The parent (general) of a Generalization is NOT placed
        #      on the current diagram.
        #   3. No other element from the parent's package is placed
        #      on the diagram — EA treats the parent's package as
        #      "represented" and omits the ghost as redundant.
        def off_canvas_parent_name_for(classifier)
          return nil unless classifier.is_a?(Ea::Model::Classifier)
          return nil unless document
          return nil unless diagram.show_parents

          gen = parent_generalization_for(classifier)
          return nil unless gen

          parent = model_index[gen.general_id]
          return nil unless parent
          return nil if placed_on_diagram?(gen.general_id)
          return nil if parent_package_represented_on_diagram?(parent)

          name = parent.name.to_s
          name.empty? ? nil : name
        end

        def parent_generalization_for(classifier)
          document.relationships.find do |rel|
            rel.is_a?(Ea::Model::Generalization) &&
              rel.specific_id == classifier.id
          end
        end

        def placed_on_diagram?(model_element_ref)
          (diagram.elements || []).any? { |e| e.model_element_ref == model_element_ref }
        end

        # Returns true when any element placed on the current diagram
        # lives in the same package as `parent`. EA suppresses the
        # parent-class ghost line in that case — the parent's package
        # is already "represented" on the diagram, so the off-canvas
        # parent is implicitly visible to the reader.
        def parent_package_represented_on_diagram?(parent)
          parent_pkg = parent.is_a?(Ea::Model::Classifier) ? parent.package_id : nil
          return false unless parent_pkg

          (diagram.elements || []).any? do |e|
            sibling = model_index[e.model_element_ref]
            sibling.is_a?(Ea::Model::Classifier) && sibling.package_id == parent_pkg
          end
        end

        # EA renders a package's child classifiers and sub-packages as
        # alphabetical "+ Name" rows in the body compartment, but
        # only when the diagram's t_diagram.ShowPackageContents flag
        # is non-zero. Returns [] when the diagram suppresses
        # package contents or the model element isn't a Package.
        # Each entry is a Struct(name:, kind:) so the renderer can
        # pick the correct per-type icon (Enumeration vs default).
        def package_content_lines_for(model_element)
          return [] unless model_element.is_a?(Ea::Model::Package)
          return [] unless diagram.show_package_contents

          children = package_children(model_element)
          return [] if children.empty?

          children.sort_by { |c| c.name.to_s }.map do |c|
            PackageContentRow.new(name: c.name.to_s, kind: row_icon_kind(c))
          end
        end

        def package_children(package)
          return [] unless model_index

          model_index.values.select do |obj|
            (obj.is_a?(Ea::Model::Classifier) && obj.package_id == package.id) ||
              (obj.is_a?(Ea::Model::Package) && obj.parent_id == package.id)
          end
        end

        # Discriminator for the per-row icon shape. EA draws a
        # list-style icon for Enumeration children (or classifiers
        # stereotyped "enumeration"), a small 13×9 folder icon for
        # sub-Packages, and a "folded paper" icon for other
        # classifiers.
        def row_icon_kind(child)
          if child.is_a?(Ea::Model::Package)
            :package
          elsif child.is_a?(Ea::Model::Enumeration) ||
                enumeration_stereotype?(child)
            :enumeration
          else
            :default
          end
        end

        def enumeration_stereotype?(child)
          return false unless child.is_a?(Ea::Model::Classifier)

          refs = child.stereotype_refs
          refs&.any? { |r| r.to_s.downcase == "enumeration" }
        end

        PackageContentRow = Struct.new(:name, :kind, keyword_init: true)

        # Computes y-coordinates for header/divider/attr compartments
        # given bounds, font size, and line count. See
        # Element::CompartmentGeometry for the coordinate math.
        CompartmentGeometry = Element::CompartmentGeometry

        # Returns true when this element's bounds are geometrically
        # inside another element's bounds in the same diagram. EA
        # shows qualified names (ParentClass::ChildClass) for
        # visually-nested classes and simple names for separately-
        # placed classes.
        def visually_nested?(element)
          my_bounds = element.bounds || element.image_bounds
          return false unless my_bounds

          (diagram.elements || []).any? do |other|
            next if other.id == element.id

            other_bounds = other.bounds || other.image_bounds
            next unless other_bounds

            bounds_contain?(other_bounds, my_bounds)
          end
        end

        def bounds_contain?(outer, inner)
          outer.x <= inner.x &&
            outer.y <= inner.y &&
            outer.x + outer.width >= inner.x + inner.width &&
            outer.y + outer.height >= inner.y + inner.height
        end

        def resolve_fill(element, classifier)
          color_resolver.fill_for(element, classifier)
        end

        def resolve_stroke
          color_resolver.stroke_for(nil)
        end

        def resolve_stroke_width
          theme.themed? ? theme.stroke_width : DEFAULT_STROKE_WIDTH
        end

        def color_resolver
          @color_resolver ||= ColorResolver.new(theme: theme)
        end

        def theme
          @theme ||= diagram.theme
        end

        def display_config
          @display_config ||= diagram.display_config
        end

        def show_attributes?
          display_config.show_attributes?
        end

        def show_operations?
          display_config.show_operations?
        end

        # EA only renders a header→content divider when there's
        # actual content below (attributes, operations, literals, or
        # tagged values). Classes with only a header (no displayed
        # features) omit the divider entirely.
        def has_content_below_header?(attr_lines, op_lines, enum_literals, tagged_values = [])
          !attr_lines.empty? || !op_lines.empty? || enum_literals.any? || tagged_values.any?
        end

        def font_resolver
          @font_resolver ||= FontResolver.new(diagram, theme: theme)
        end

        def element_filter
          @element_filter ||= Element::Filter.new(model_index: model_index)
        end

        def classifier_for(element)
          ref = element.model_element_ref
          return nil unless ref

          candidate = model_index[ref]
          return nil unless candidate.is_a?(Ea::Model::Classifier) ||
                            candidate.is_a?(Ea::Model::InstanceSpecification)

          candidate
        end

        # Lookup proc for AttributeLineBuilder: resolves a
        # classifier id to the Classifier instance. Returns nil
        # when not found or not a Classifier.
        def attribute_lookup
          lambda { |id| model_index[id] if model_index && model_index[id].is_a?(Ea::Model::Classifier) }
        end

        def model_element_for(element)
          ref = element.model_element_ref
          return nil unless ref

          model_index[ref]
        end

        def translate_bounds(b)
          return b unless canvas

          # Reuse the model's Bounds value object rather than an
          # ad-hoc OpenStruct. Keeps the type uniform across the
          # pipeline and avoids require "ostruct".
          Ea::Model::Bounds.new(
            x: canvas.translate_x(b.x),
            y: canvas.translate_y(b.y),
            width: b.width,
            height: b.height
          )
        end
      end
    end
  end
end
