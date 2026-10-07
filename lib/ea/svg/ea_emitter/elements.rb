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
          @drawn_bounds = {}
          @divider_y = {}
          ordered_elements.flat_map { |e| groups_for(e) }
        end

        # Final drawn Bounds per model element reference, captured
        # during rendering (grown heights for overflowing classifiers,
        # autosized outlines for packages). Connector emission re-docks
        # direct lines against these — EA clips connector rays at the
        # drawn outlines, never the stored rect.
        attr_reader :drawn_bounds

        # Logical-space header divider y per model element ref, for
        # connector row-slot docking (EA docks horizontal exits at
        # divider_y + 13, the first attribute-row slot).
        attr_reader :divider_y

        private

        def ordered_elements
          (diagram.elements || []).sort_by { |e| e.z_order || 0 }
        end

        def groups_for(element)
          return [] if element_filter.skip?(element)

          context = build_context(element)
          return [] unless context

          record_drawn_bounds(element, context)
          Compartment.render_all(context).compact
        end

        # Logical-space drawn bounds: stored x/y with the RENDERED
        # height (grown classifiers) and rendered width (autosized
        # packages). Heights/widths are translation-invariant, so the
        # connector emitters can redock in logical space and run the
        # normal canvas translation afterwards.
        def classifier_package?(classifier)
          classifier.is_a?(Ea::Model::Package)
        end

        def package_stereotype(context)
          context.classifier.stereotype_refs.first.to_s
        end

        def record_drawn_bounds(element, context)
          return unless element.model_element_ref

          raw = element.bounds || element.image_bounds
          return unless raw

          width = raw.width
          if classifier_package?(context.classifier)
            tab = Element::PackageShapeRenderer.autosized_tab_width(
              label: context.classifier.name.to_s,
              stereotype: package_stereotype(context),
              size: context.size
            )
            width = [raw.width, tab + Element::PackageShapeRenderer::TAB_BODY_EXTRA].max
          end
          @drawn_bounds[element.model_element_ref] = Ea::Model::Bounds.new(
            x: raw.x, y: raw.y,
            width: width,
            height: context.bounds.height
          )
          return unless context.geometry

          @divider_y[element.model_element_ref] = context.geometry.divider_y
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
                                                                family: family,
                                                                off_canvas_parent_name: parent_name,
                                                                foreign_package_name: foreign_package_name_for(classifier),
                                                                suppress_stereotypes: suppress_stereotypes?) : []
          is_classifier = classifier.is_a?(Ea::Model::Classifier)
          # Interfaces DO render attribute compartments when they own
          # attribute rows (936AA434/Surface lists its nine 19107
          # attributes); the earlier corpus evidence for
          # header-only interfaces was zero-attribute leaf types.
          attr_lines = if is_classifier && show_attributes? &&
                          attributes_visible?(element)
                         Element::AttributeRenderer.lines_for(
                           classifier, lookup: attribute_lookup,
                           exclude_association_ids: drawn_association_ids
                         )
                       else
                         []
                       end
          op_lines = if is_classifier && show_operations? && operations_visible?(element)
                        Element::OperationRenderer.lines_for(classifier)
                      else
                        []
                      end
          geometry = compartment_geometry(bounds, size, attr_lines, op_lines,
                                           tagged_values_for(classifier).size,
                                           header_lines, classifier: classifier,
                                           constraints_count: constraints_for(classifier).size,
                                           marker_count: marker_lines_for(classifier).size,
                                           enum_literals_count: enum_row_count_for(classifier))
          # EA suppresses the whole attribute compartment when its
          # rows do not fit the stored box height (never truncates
          # rows) - the AOS box on CityFurniture hides its
          # association property this way. The gate compares the last
          # baseline + text descent (~4px) against the box bottom:
          # TK_PositionType keeps 7 rows ending 6px above the bottom,
          # while a 13px-tighter box loses them all.
          # The drop applies only to association-derived property
          # rows (AOS/CityFurniture). When the element has REAL
          # attributes EA instead GROWS the drawn box past the
          # stored height and shows every row (0CABA7D7: parent at
          # stored h44 draws at h59 with +minimumOccurs visible).
          if attr_lines.any? &&
             !classifier.properties.to_a.any? { |p| !p.association_id } &&
             geometry.attr_bottom_y.to_i > bounds.y + bounds.height
            attr_lines = []
            geometry = compartment_geometry(bounds, size, attr_lines, op_lines,
                                             tagged_values_for(classifier).size,
                                             header_lines, classifier: classifier,
                                             constraints_count: constraints_for(classifier).size,
                                           marker_count: marker_lines_for(classifier).size,
                                           enum_literals_count: enum_row_count_for(classifier))
          end
          # EA suppresses the operations compartment when its rows
          # overflow the stored box height (same rule as attributes).
          if op_lines.any? && geometry.op_first_y &&
             geometry.op_bottom_y.to_i > bounds.y + bounds.height
            op_lines = []
            geometry = compartment_geometry(bounds, size, attr_lines, op_lines,
                                             tagged_values_for(classifier).size,
                                             header_lines, classifier: classifier,
                                             constraints_count: constraints_for(classifier).size,
                                           marker_count: marker_lines_for(classifier).size,
                                           enum_literals_count: enum_row_count_for(classifier))
          end
          # Real attributes grow the DRAWN box past the stored
          # height instead of being dropped (0CABA7D7: stored h44
          # draws at h59). Grown height = last row baseline + EA's
          # ~8px bottom padding. Render-local: the diagram-level
          # canvas still derives from stored bounds.
          # content_bottom_y is nil when no compartment has rows;
          # op_bottom_y is NOT a sentinel (it reports the op-divider
          # position even with zero operations), so it must stay out
          # of the max.
          grown_bottom = geometry.content_bottom_y.to_i
          if attr_lines.any? && grown_bottom.positive? &&
             grown_bottom + 8 > bounds.y + bounds.height
            bounds = Ea::Model::Bounds.new(
              x: bounds.x, y: bounds.y,
              width: bounds.width,
              height: grown_bottom + 8 - bounds.y
            )
          end
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
            marker_lines: marker_lines_for(classifier),
            package_content_lines: package_content_lines_for(model_element),
            geometry: geometry,
            theme: theme,
            canvas: canvas,
            diagram: diagram,
            model_index: model_index,
            off_canvas_parent_name: parent_name
          )
        end

        def compartment_geometry(bounds, size, attr_lines, op_lines,
                                 tagged_count, header_lines, classifier: nil,
                                 constraints_count: 0, marker_count: 0,
                                 enum_literals_count: 0)
          CompartmentGeometry.new(bounds: bounds, size: size,
                                   header_ghost: header_lines.any? &&
                                                  %i[italic italic_tight].include?(header_lines.first.last),
                                   header_ghost_tight: header_lines.any? &&
                                                       header_lines.first.last == :italic_tight,
                                   header_lines_count: header_lines.size,
                                   attr_lines_count: attr_lines.size,
                                   op_lines_count: op_lines.size,
                                   tagged_values_count: tagged_count,
                                   constraints_count: constraints_count,
                                   marker_count: marker_count,
                                   enum_literals_count: enum_literals_count,
                                   header_top_padding: header_padding_for(header_lines, classifier),
                                   header_line_offset: theme.compartments.header_line_offset,
                                   divider_offset: theme.compartments.divider_offset,
                                   attr_line_offset: theme.compartments.attr_line_offset,
                                   attr_first_offset: attr_first_offset_for(attr_lines))
        end

        # EA seats a stereotype line 3px higher than a bare class name
        # (first baseline +16 vs +19 at 7pt) - and Enumeration /
        # Interface elements seat their stereotype 3px higher still
        # (+13). Corpus-verified by identity-matched elements:
        # Interface +13 x44 vs +16 x17, Enumeration +13 x13 vs +16
        # x3, Class/Object/DataType +16 x515.
        def header_padding_for(header_lines, classifier)
          first = header_lines.first
          return theme.compartments.header_top_padding unless first

          if first.last == :italic || first.last == :italic_tight
            6 # ghost-led: EA seats the right-aligned ghost at +13
          elsif first.first.to_s.start_with?("«")
            fallback_stereotype_label?(first.first, classifier) ? 6 : 9
          else
            theme.compartments.header_top_padding
          end
        end

        # EA seats the FALLBACK stereotype label («enumeration»,
        # «interface», … from the element TYPE with no stored
        # stereotype) 3px higher than a class name; EXPLICIT
        # stereotype labels («CodeList», «TopLevelFeatureType»)
        # keep the class padding (C45FC57E's «CodeList» seats at
        # +16 while fallback «enumeration» boxes seat at +13).
        FALLBACK_LABELS = {
          Ea::Model::Enumeration => "«enumeration»",
          Ea::Model::Interface => "«interface»",
          Ea::Model::DataType => "«dataType»",
          Ea::Model::PrimitiveType => "«primitive»",
          Ea::Model::Signal => "«signal»"
        }.freeze

        def fallback_stereotype_label?(label, classifier)
          return false if classifier.respond_to?(:stereotype_refs) &&
                          classifier.stereotype_refs&.any?

          FALLBACK_LABELS.any? do |type, expected|
            classifier.is_a?(type) && label == expected
          end
        end

        # t_diagram pdata HideEStereo=1 suppresses every stereotype
        # line on the diagram - instance boxes ("Case C25" renders
        # no «featureType» despite every instance carrying one) and
        # classifier boxes alike.
        def suppress_stereotypes?
          diagram.style.to_s.match?(/HideEStereo=1/)
        end

        # A stereotype group header («Property») sits 4px below where
        # plain rows start (divider+18 vs divider+14 at 7pt).
        def attr_first_offset_for(attr_lines)
          attr_lines.first.to_s.start_with?("«") ? 11 : 7
        end

        # EA's per-instance attribute visibility toggles (ObjectStyle
        # AttPub/AttPri/AttPro/AttPkg). When ANY toggle is stored, only
        # attributes of an enabled visibility class render; the GM_*
        # geometry boxes carry all four at 0 and render header-only.
        def attributes_visible?(element)
          toggles = visibility_toggles(element)
          return true if toggles.empty?

          toggles.values.any? { |v| v == "1" }
        end

        def visibility_toggles(element)
          style = element.style || {}
          %i[attpub attpri attpro attpkg]
            .each_with_object({}) { |k, acc| acc[k] = style[k] if style.key?(k) }
        end

        def operations_visible?(element)
          style = element.style || {}
          keys = %i[oppub oppri oppro oppkg]
          present = keys.select { |k| style.key?(k) }
          return true if present.empty?

          present.any? { |k| style[k] == "1" }
        end

        def drawn_association_ids
          (diagram.connectors || []).select(&:renderable?)
                                    .map(&:relationship_ref).compact.to_set
        end

        def enum_literals_for(classifier)
          return [] unless classifier.is_a?(Ea::Model::Enumeration)

          classifier.literals || []
        end

        # The "literals" caption occupies a row slot when any
        # literal carries a stored code value.
        def enum_row_count_for(classifier)
          literals = enum_literals_for(classifier)
          caption = literals.any? { |l| !l.value.to_s.empty? && l.value.to_s != l.name.to_s }
          literals.size + (caption ? 1 : 0)
        end

        def tagged_values_for(classifier)
          return [] unless classifier.is_a?(Ea::Model::Classifier)

          classifier.tagged_values || []
        end

        # Real OCL constraints render trailing, after the content
        # compartment; the {root}/{leaf} marker renders its own
        # compartment between the divider and the attributes.
        def constraints_for(classifier)
          return [] unless classifier.is_a?(Ea::Model::Classifier)

          classifier.constraints || []
        end

        def marker_lines_for(classifier)
          return [] unless classifier.is_a?(Ea::Model::Classifier)

          marker_line = root_leaf_marker_for(classifier)
          marker_line ? [marker_constraint(marker_line)] : []
        end

        # EA renders the element's Root/Leaf checkboxes as {root},
        # {leaf}, or {root,leaf} first in the constraints compartment
        # (t_object.IsRoot/IsLeaf — verified on LanguageCode boxes).
        def root_leaf_marker_for(classifier)
          parts = []
          parts << "root" if classifier.is_root
          parts << "leaf" if classifier.is_leaf
          parts.empty? ? nil : "{#{parts.join(',')}}"
        end

        def marker_constraint(text)
          name = text[1..-2]
          Ea::Model::Constraint.new(name: name, kind: "Marker")
        end

        # EA qualifies a placed classifier's header with its owning
        # package name ("OwningPackage::Name") exactly when the
        # diagram's t_diagram.ShowForeign flag is set AND the
        # classifier lives in a different package than the diagram
        # (descendant packages included). Corpus-verified (450
        # diagrams): ShowForeign=0 renders plain everywhere.
        def foreign_package_name_for(classifier)
          return nil unless diagram.show_foreign
          return nil unless classifier.is_a?(Ea::Model::Classifier)

          pkg_id = classifier.package_id
          return nil if pkg_id.nil? || pkg_id == diagram.package_id

          pkg = model_index ? model_index[pkg_id] : nil
          return nil unless pkg.is_a?(Ea::Model::Package)

          name = pkg.name.to_s
          name.empty? ? nil : name
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

        # EA suppresses the parent-class ghost line only when the
        # parent's package is itself placed on the diagram as a
        # package element. A mere same-package classifier does NOT
        # suppress it — verified against EA-published reference SVGs
        # (CityFurniture renders the ghost for AbstractOccupiedSpace
        # although the class shares its parent's package).
        def parent_package_represented_on_diagram?(parent)
          parent_pkg = parent.is_a?(Ea::Model::Classifier) ? parent.package_id : nil
          return false unless parent_pkg

          (diagram.elements || []).any? { |e| e.model_element_ref == parent_pkg }
        end

        # EA renders a package's child classifiers and sub-packages as
        # alphabetical "+ Name" rows in the body compartment, but
        # only when the diagram's t_diagram.ShowPackageContents flag
        # is non-zero. Returns [] when the diagram suppresses
        def package_content_lines_for(model_element)
          return [] unless model_element.is_a?(Ea::Model::Package)
          return [] unless diagram.show_package_contents

          children = package_children(model_element)
          return [] if children.empty?

          children.sort_by { |c| c.name.to_s }.map do |c|
            PackageContentRow.new(name: c.name.to_s, kind: row_icon_kind(c))
          end
        end
        public :package_content_lines_for

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
