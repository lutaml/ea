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
          image_layer = emit_images
          layers << image_layer if image_layer

          %(<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN" "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">\n\n<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="#{canvas.width_cm}" height="#{canvas.height_cm}" viewBox="#{canvas.view_box}">\n<title></title>\n<desc>Created with Enterprise Architect (Build: #{BUILD_ID}) 2</desc>\n#{layers.join("\n")}\n</svg>)
        end

        # Walks t_image rows (when the document carries a Database
        # with an :images collection) and invokes EmfRenderer on
        # each. Emits an `<image>` element per successfully converted
        # SVG, or returns nil when no images or all conversions fail.
        #
        # The emfsvg gem currently can't parse EA's specific EMF
        # variant (see TODO.diagrams/87 + TODO.complete/56). Until
        # upstream emfsvg supports it, this method returns nil
        # gracefully. The wiring is correct infrastructure for when
        # emfsvg catches up.
        def emit_images
          return nil unless document
          return nil unless document.is_a?(Ea::Qea::Database)

          images = document.collections[:images] || []
          return nil if images.empty?

          fragments = images.filter_map { |image| render_image(image) }
          return nil if fragments.empty?

          %(<g id="images">\n#{fragments.join("\n")}\n</g>)
        end

        def render_image(image)
          svg = Ea::Image::EmfRenderer.render(image.bytes)
          return nil unless svg

          %(<g>#{svg}</g>)
        end
        private :render_image
      end
    end
  end
end
