# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Compartment
        # Renders the "(from ParentPackage)" italic subtitle at the
        # bottom of a placed PACKAGE element's body.
        #
        # EA renders the subtitle exactly when the diagram's
        # t_diagram.ShowForeign flag is set AND the package's parent
        # differs from the diagram's own package. Corpus-verified
        # (379 diagrams, 378 exact): classifiers never render the
        # subtitle, and ShowForeign=0 diagrams render none.
        module PackageFromParent
          Y_OFFSET_FROM_BOTTOM = 5

          module_function

          def render(context)
            pkg = context.model_element
            return nil unless pkg.is_a?(Ea::Model::Package)

            diagram = context.diagram
            return nil unless diagram&.show_foreign

            parent_id = pkg.parent_id
            return nil if parent_id.nil? || parent_id.empty?
            return nil if parent_id == diagram.package_id

            parent = context.model_index_for(parent_id)
            return nil unless parent.is_a?(Ea::Model::Package)

            name = parent.name.to_s
            return nil if name.empty?

            subtitle("(from #{name})", context)
          end

          module_function :render

          def subtitle(text, context)
            bounds = context.bounds
            fill = context.theme.attribute_text_color
            y = bounds.y + bounds.height - Y_OFFSET_FROM_BOTTOM
            # EA centers the subtitle by its integer textLength inside
            # the package BODY and floors x.
            body_width = Element::PackageShapeRenderer.body_width_for(
              label: context.model_element.name.to_s,
              stereotype: nil, size: context.size
            )
            len = TextRenderer.estimate_width(
              text, context.size, nil,
              family: context.family, style: "italic"
            ).round
            x = (bounds.x + (body_width - len) / 2.0).floor
            body = TextRenderer.new(
              content: text, x: x, y: y,
              family: context.family, size: context.size,
              size_unit: context.size_unit, fill: fill,
              style: "italic"
            ).to_svg
            wrap(body, fill)
          end
          module_function :subtitle

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
