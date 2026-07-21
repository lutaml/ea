# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Emits connector labels (role names, multiplicities) at the
      # EA-recorded offset from the connector endpoints. Each label
      # box has its own position decoded from the EA LLB/LLT/LRT/LRB
      # geometry slots.
      class Labels
        DEFAULT_FAMILY = "Calibri"
        DEFAULT_SIZE = 10

        attr_reader :diagram, :canvas

        def initialize(diagram, canvas: nil)
          @diagram = diagram
          @canvas = canvas
        end

        def render
          texts = visible_connectors.filter_map { |c| texts_for(c) }
          return "" if texts.empty?

          blocks = texts.flatten
          %(<g style="stroke-width:1;stroke-linecap:round;stroke-linejoin:bevel; fill:#000000;fill-opacity:1.00; stroke:#000000; stroke-opacity:0.00">\n#{blocks.join("\n")}\n</g>)
        end

        private

        def visible_connectors
          (diagram.connectors || []).reject(&:hidden)
        end

        def texts_for(connector)
          points = connector.waypoints.filter_map { |w| w.position && [w.position.x, w.position.y] }
          return nil if points.size < 2

          source_pt = points.first
          target_pt = points.last

          boxes = connector.label_boxes || {}
          texts = []
          if (box = boxes["llb"]) && box["ox"] && box["oy"]
            x, y = translate_point([source_pt[0] + box["ox"], source_pt[1] + box["oy"]])
            texts << text_at(x, y, connector.label.to_s)
          end
          if (box = boxes["lrt"]) && box["ox"] && box["oy"]
            x, y = translate_point([target_pt[0] + box["ox"], target_pt[1] + box["oy"]])
            texts << text_at(x, y, connector.label.to_s)
          end
          texts.empty? ? nil : texts
        end

        def text_at(x, y, text)
          return nil if text.nil? || text.empty?

          %(  <text x="#{format('%.2f', x)}" y="#{format('%.2f', y)}" textLength="#{text.length * 6}" style="font-family:#{DEFAULT_FAMILY}; font-weight:0; font-style:normal; font-size:#{DEFAULT_SIZE}px; fill:#000000;fill-opacity:1.00; stroke:#000000; stroke-opacity:0.00 stroke-width:0; white-space: pre;" xml:space="preserve">#{escape(text)}</text>)
        end

        def translate_point(p)
          return p unless canvas

          [canvas.translate_x(p[0]), canvas.translate_y(p[1])]
        end

        def escape(text)
          text.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;").gsub("\"", "&quot;")
        end
      end
    end
  end
end
