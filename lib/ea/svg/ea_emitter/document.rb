# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Top-level orchestrator: emits a complete standalone SVG
      # document matching EA's structure. Calls the layer emitters
      # in EA's canonical order.
      class Document
        BUILD_ID = "1628"

        attr_reader :diagram, :model_index, :options

        def initialize(diagram, model_index:, **_options)
          @diagram = diagram
          @model_index = model_index
        end

        def render
          canvas = Canvas.from(diagram)
          layers = [
            Background.render(canvas),
            Elements.new(diagram, model_index: model_index, canvas: canvas).render,
            Connectors.new(diagram, canvas: canvas).render,
            Markers.new(diagram, model_index: model_index, canvas: canvas).render,
            Labels.new(diagram, canvas: canvas).render
          ].reject { |s| s.nil? || s.empty? }

          <<~SVG
            <?xml version="1.0" encoding="UTF-8" standalone="no"?>
            <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN" "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">

            <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="#{canvas.width_cm}" height="#{canvas.height_cm}" viewBox="#{canvas.view_box}">
            <title></title>
            <desc>Created with Enterprise Architect (Build: #{BUILD_ID}) 2</desc>

            #{layers.join("\n\n")}
            </svg>
          SVG
        end
      end
    end
  end
end
