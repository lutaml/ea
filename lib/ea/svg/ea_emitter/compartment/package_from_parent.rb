# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Compartment
        # Renders the "(from ParentPackage)" italic subtitle inside
        # a Package element's body. EA emits this when a package is
        # placed on a diagram whose own package is NOT the package's
        # parent — the subtitle shows the package's actual parent
        # context so the reader can locate it in the model tree.
        #
        # Format: italic, small font, centered horizontally in the
        # element body, positioned near the bottom of the body.
        module PackageFromParent
          Y_OFFSET_FROM_BOTTOM = 5

          module_function

          def render(context)
            pkg = context.model_element
            return nil unless pkg.is_a?(Ea::Model::Package)

            parent_name = parent_name_for(pkg, context)
            return nil if parent_name.nil? || parent_name.empty?

            subtitle = "(from #{parent_name})"
            bounds = context.bounds
            fill = context.theme.attribute_text_color
            y = bounds.y + bounds.height - Y_OFFSET_FROM_BOTTOM
            estimated_width = subtitle.length * context.size * 0.5
            x = bounds.x + (bounds.width - estimated_width) / 2.0
            text = TextRenderer.new(
              content: subtitle, x: x, y: y,
              family: context.family, size: context.size,
              size_unit: context.size_unit, fill: fill,
              style: "italic"
            ).to_svg
            wrap(text, fill)
          end

          # Resolves the package's parent's name via the model index.
          # Returns nil when:
          #   - the package has no parent
          #   - the parent IS the diagram's own package (already in context)
          #   - the parent is ALSO placed on the current diagram
          #   - every placed Package on the diagram shares the same
          #     parent_id (diagram is implicitly about that parent's
          #     children — EA omits the subtitle as redundant)
          #   - the parent's name equals the placed package's name
          #     (e.g. an inner "3D都市モデル" nested inside an outer
          #     "3D都市モデル" — the subtitle would be tautological)
          #   - the diagram's name contains any placed Package's name
          #     as a substring (the diagram is implicitly "about" that
          #     package — subtitles would be redundant). Verified
          #     against plateau's "3D都市モデル応用スキーマと他のスキーマとの関係"
          #     diagram, which contains the placed name "3D都市モデル"
          #     and renders 0 subtitles in EA's reference.
          def parent_name_for(pkg, context)
            parent_id = pkg.parent_id
            return nil if parent_id.nil? || parent_id.empty?
            return nil if parent_id == context.diagram&.package_id
            return nil if parent_on_diagram?(parent_id, context)
            return nil if uniform_package_parent?(context)
            return nil if diagram_name_contains_placed_package?(context)

            parent = context.model_index_for(parent_id)
            return nil unless parent.is_a?(Ea::Model::Package)
            return nil if parent.name.to_s == pkg.name.to_s

            parent.name.to_s.empty? ? nil : parent.name
          end
          module_function :parent_name_for

          # Returns true when the diagram has 2+ placed Packages and
          # every placed Package shares the same parent_id. EA treats
          # such diagrams as "children of X" overviews and suppresses
          # the (from X) subtitle on every element.
          def uniform_package_parent?(context)
            diagram = context.diagram
            return false unless diagram && context.model_index

            placed_pkg_parents = (diagram.elements || []).filter_map do |el|
              me = context.model_index[el.model_element_ref]
              next nil unless me.is_a?(Ea::Model::Package)

              me.parent_id
            end
            placed_pkg_parents.size > 1 && placed_pkg_parents.uniq.size == 1
          end
          module_function :uniform_package_parent?

          def parent_on_diagram?(parent_id, context)
            diagram = context.diagram
            return false unless diagram

            (diagram.elements || []).any? do |e|
              e.model_element_ref == parent_id
            end
          end
          module_function :parent_on_diagram?

          # Returns true when the diagram's name contains any placed
          # Package's name as a substring. EA omits all subtitles in
          # such diagrams — the name itself signals which package is
          # the subject, making subtitles redundant.
          def diagram_name_contains_placed_package?(context)
            diagram = context.diagram
            return false unless diagram && context.model_index

            name = diagram.name.to_s
            return false if name.empty?

            (diagram.elements || []).any? do |el|
              me = context.model_index[el.model_element_ref]
              next false unless me.is_a?(Ea::Model::Package)

              pkg_name = me.name.to_s
              !pkg_name.empty? && name.include?(pkg_name)
            end
          end
          module_function :diagram_name_contains_placed_package?

          def wrap(body, fill)
            group_style = "stroke-width:1;stroke-linecap:round;" \
                          "stroke-linejoin:bevel; fill:#{fill};" \
                          "fill-opacity:1.00; stroke:#000000;" \
                          " stroke-opacity:0.00"
            %(<g style="#{group_style}">\n#{body}\n</g>)
          end
          module_function :wrap
        end
      end
    end
  end
end
