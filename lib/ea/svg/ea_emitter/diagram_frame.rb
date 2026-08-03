# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Emits the diagram frame: outer border + name tab. EA renders
      # every diagram with a 1px black border forming a rectangle
      # inset 6px from the canvas edge, plus a "tab" polygon in the
      # upper-left containing the diagram type + name text.
      #
      # Layout:
      #   ┌───┐
      #   │tab│──────────────────┐
      #   └───┘                  │
      #                          │
      #   (diagram contents)     │
      #                          │
      #   ┌──────────────────────┘
      #
      # Format observed in EA reference SVGs:
      #   <g style="...stroke-width:1;stroke-linecap:square;
      #              stroke-linejoin:miter; fill:#000000;
      #              fill-opacity:0.00; stroke:#000000;
      #              stroke-opacity:1.00">
      #     <path d="M 6 6 L 6 H-6 W-6 W-6 6 L 6 6"/>
      #   </g>
      #   <g style="...fill:#FFFFFF;...">
      #     <polygon points="6 26 X 26 X+13 12 X+13 6 6 6 6 26"/>
      #   </g>
      #   <g style="...">
      #     <text x="11" y="19" ...>class DiagramName</text>
      #   </g>
      class DiagramFrame
        attr_reader :canvas, :theme

        def initialize(canvas:, theme: nil)
          @canvas = canvas
          @theme = theme || Ea::Theme::Registry.default
        end

        def layers(diagram)
          return [] if canvas.nil?

          [
            border_layer(canvas),
            tab_layer(canvas, diagram),
            tab_label_layer(canvas, diagram)
          ].compact
        end

        private

        def border_layer(canvas)
          d = border_path_d(canvas)
          body = %(<path d="#{d}" shape-rendering="auto"/>)
          Layer.new(style_key: :frame_border, style: BORDER_STYLE, body: body)
        end

        def tab_layer(canvas, diagram)
          points = tab_points(canvas, diagram)
          body = %(<polygon points="#{points}" shape-rendering="auto"   style="fill-rule:evenodd;"/>)
          Layer.new(style_key: :frame_tab, style: TAB_STYLE, body: body)
        end

        def tab_label_layer(canvas, diagram)
          label = tab_label(diagram)
          return nil unless label

          body = build_label_text(label)
          Layer.new(style_key: :frame_label, style: LABEL_STYLE, body: body)
        end

        def border_path_d(canvas)
          inset = theme.frame.inset
          right = canvas.width - inset
          bottom = canvas.height - inset
          "M #{inset} #{inset} L #{inset} #{bottom} L #{right} #{bottom} L #{right} #{inset} L #{inset} #{inset}"
        end

        def tab_points(canvas, diagram)
          label_width = tab_label_width(diagram)
          x1 = theme.frame.inset
          x2 = x1 + label_width
          x3 = x2 + theme.frame.tab_slant
          top1 = theme.frame.inset
          top2 = theme.frame.inset + theme.frame.tab_height
          "#{x1} #{top2} #{x2} #{top2} #{x3} #{top1 + theme.frame.tab_height - theme.frame.tab_slant} #{x3} #{top1} #{x1} #{top1} #{x1} #{top2}"
        end

        def tab_label(diagram)
          type = diagram_label_prefix(diagram)
          return nil unless type

          "#{type} #{diagram.name}"
        end

        def diagram_label_prefix(diagram)
          case diagram.diagram_type&.downcase
          when "logical" then "class"
          when "package" then "pkg"
          when "usecase" then "uc"
          when "sequence" then "seq"
          when "activity" then "act"
          when "statechart" then "sm"
          when "deployment" then "dep"
          when "component" then "comp"
          when "object" then "object"
          when "custom", "conceptual" then nil
          else diagram.diagram_type&.downcase
          end
        end

        def tab_label_width(diagram)
          label = tab_label(diagram)
          return theme.package.default_tab_width unless label

          text_width = Ea::Svg::EaEmitter::TextRenderer.estimate_width(
            label, theme.font_size || 7, theme.text_width_factor
          ).round
          text_width + theme.frame.tab_padding
        end

        def build_label_text(label)
          TextRenderer.new(
            content: label,
            x: theme.frame.tab_label_x, y: theme.frame.tab_label_y,
            family: theme.font_family || "Calibri",
            size: theme.font_size || 7,
            weight: theme.text_weight_bold,
            size_unit: theme.font_size_unit,
            fill: "#000000",
            stroke_in_text: theme.stroke_in_text_color,
            width_factor: theme.text_width_factor
          ).to_svg
        end

        BORDER_STYLE = "stroke-width:1;stroke-linecap:square;stroke-linejoin:miter; fill:#000000;fill-opacity:0.00; stroke:#000000; stroke-opacity:1.00"
        TAB_STYLE = "stroke-width:1;stroke-linecap:square;stroke-linejoin:miter; fill:#FFFFFF;fill-opacity:1.00; stroke:#000000; stroke-opacity:1.00"
        LABEL_STYLE = "stroke-width:1;stroke-linecap:square;stroke-linejoin:miter; fill:#000000;fill-opacity:1.00; stroke:#000000; stroke-opacity:0.00"
      end
    end
  end
end
