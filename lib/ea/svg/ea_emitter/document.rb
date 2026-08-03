# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Top-level orchestrator: emits a complete standalone SVG
      # document matching EA's encoding. Bound computation and
      # layer sequencing delegated to BoundsCalculator and
      # LayerSequencer respectively (SRP).
      class Document
        BUILD_ID = "1624"

        attr_reader :diagram, :model_index, :frame, :document

        def initialize(diagram, model_index:, frame: true, document: nil, **_options)
          @diagram = diagram
          @model_index = model_index
          @frame = frame
          @document = document
        end

        def render
          canvas = Canvas.from(diagram, model_index: model_index)
          layers = LayerSequencer.new(diagram, model_index: model_index,
                                        canvas: canvas, frame: frame,
                                        document: document)
                                  .layers
                                  .reject { |s| s.nil? || s.empty? }

          %(<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN" "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">\n\n<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="#{canvas.width_cm}" height="#{canvas.height_cm}" viewBox="#{canvas.view_box}">\n<title></title>\n<desc>Created with Enterprise Architect (Build: #{BUILD_ID}) 2</desc>\n#{layers.join("\n")}\n</svg>)
        end
      end
    end
  end
end
