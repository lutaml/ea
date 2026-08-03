# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Compartment
        # Package-contents compartment. Renders the package's child
        # classifiers and sub-packages as a list of "+ Name" rows in
        # the body, matching EA's package-on-diagram rendering. Each
        # row also draws a small per-type icon to the left of the
        # text (Enumeration gets a list-style icon; other classifiers
        # get the "folded paper" silhouette).
        module PackageContents
          ROW_HEIGHT = 16
          ICON_X_OFFSET = 5
          TEXT_X_OFFSET = 23

          module_function

          def render(context)
            rows = context.package_content_lines
            return nil if rows.nil? || rows.empty?

            bounds = context.bounds
            first_y = context.geometry.attr_first_y
            blocks = rows.each_with_index.flat_map do |row, idx|
              y_top = first_y - 11 + (idx * ROW_HEIGHT)
              y_text = first_y + (idx * ROW_HEIGHT)
              [
                icon_block(bounds, y_top, row.kind),
                text_block(bounds, y_text, row.name, context)
              ]
            end
            wrap_group(blocks.join("\n"))
          end

          def wrap_group(body)
            %(<g style="#{group_style}">\n#{body}\n</g>)
          end
          module_function :wrap_group

          def group_style
            "stroke-width:1;stroke-linecap:square;stroke-linejoin:bevel; " \
              "fill-opacity:1.00; stroke-opacity:1.00"
          end
          module_function :group_style

          def icon_block(bounds, y_top, kind)
            Element::RowIconRenderer.render(
              x_pos: bounds.x + ICON_X_OFFSET,
              y_pos: y_top,
              kind: kind || :default
            )
          end
          module_function :icon_block

          def text_block(bounds, y, name, context)
            TextRenderer.new(
              content: "+ #{name}",
              x: bounds.x + TEXT_X_OFFSET,
              y: y,
              family: context.family, size: context.size,
              size_unit: context.size_unit,
              fill: context.theme.attribute_text_color
            ).to_svg
          end
          module_function :text_block
        end
      end
    end
  end
end
