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

          # EA draws the subtitle 15px BELOW the body bottom (outside
          # the box) — verified against EA-published package SVGs.
          Y_OFFSET_FROM_BOTTOM = 15

          LINE_PITCH = 13
          WRAP_PADDING = 15

          def subtitle(text, context)
            bounds = context.bounds
            fill = context.theme.attribute_text_color
            y = bounds.y + bounds.height + Y_OFFSET_FROM_BOTTOM
            # EA word-wraps the subtitle to the package BODY width
            # (minus padding), centers each line by its integer
            # textLength inside the body, and floors x; successive
            # lines pitch +13 (05DF5000: "(from ISO 19115-1:2014
            # Metadata" / "Fundamentals)" at y 123/136).
            body_width = bounds.width
            lines = wrap_lines(text, context, body_width - WRAP_PADDING)
            bodies = lines.each_with_index.map do |line, i|
              len = TextRenderer.estimate_width(
                line, context.size, nil,
                family: context.family, style: "italic"
              ).round
              x = (bounds.x + (body_width - len) / 2.0).floor
              TextRenderer.new(
                content: line, x: x, y: y + i * LINE_PITCH,
                family: context.family, size: context.size,
                size_unit: context.size_unit, fill: fill,
                style: "italic"
              ).to_svg
            end
            wrap(bodies.join("\n"), fill)
          end
          module_function :subtitle

          # EA carries the break space onto the broken line: line 1
          # is "(from ... Metadata - " with the trailing space, and
          # its textLength includes it (05DF5000: tl 146).
          def wrap_lines(text, context, max_width)
            words = text.split(" ")
            return [text] if words.size <= 1

            lines = []
            current = +""
            words.each do |word|
              candidate = current.empty? ? word : "#{current} #{word}"
              if !current.empty? && TextRenderer.estimate_width(
                candidate, context.size, nil,
                family: context.family, style: "italic"
              ) > max_width
                lines << "#{current} "
                current = word
              else
                current = candidate
              end
            end
            lines << current unless current.empty?
            lines
          end
          module_function :wrap_lines

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
