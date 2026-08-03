# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Sequences SVG layer output in EA's canonical order:
      #
      #   1. Background <g>
      #   2. (optional) Diagram frame: border + tab + label
      #   3. Per-element groups (shape, header, divider, attrs)
      #   4. Connector + marker groups (merged by style)
      #   5. Labels <g>
      #
      # Reads diagram.theme once and passes to all child renderers
      # so theme settings (font, colors, stroke width) apply
      # uniformly across the entire SVG output.
      #
      # Document delegates the layer assembly here so the Document
      # class shrinks to SVG envelope construction.
      class LayerSequencer
        DEFAULT_STROKE_WIDTH = 2

        attr_reader :diagram, :model_index, :canvas, :frame_enabled, :theme,
                    :document

        def initialize(diagram, model_index:, canvas:, frame: false, document: nil)
          @diagram = diagram
          @model_index = model_index
          @canvas = canvas
          @frame_enabled = frame
          @theme = diagram.theme
          @document = document
        end

        def layers
          layers = [Background.render(canvas)]
          layers += frame_layers if frame_enabled
          layers += element_layers
          layers += connector_layers
          layers << labels_layer
          layers << ghost_labels_layer
          layers
        end

        private

        def frame_layers
          DiagramFrame.new(canvas: canvas, theme: theme).layers(diagram).map(&:to_svg)
        end

        def element_layers
          Elements.new(diagram, model_index: model_index, canvas: canvas,
                        document: document).groups
        end

        def connector_layers
          connector_layers_raw = Connectors.new(diagram, canvas: canvas,
                                                  grouped: true,
                                                  stroke_width: DEFAULT_STROKE_WIDTH).layers
          marker_layers_raw = Markers.new(diagram, model_index: model_index,
                                           canvas: canvas, grouped: true,
                                           stroke_width: DEFAULT_STROKE_WIDTH).layers
          merge_layers_by_style(connector_layers_raw + marker_layers_raw).map(&:to_svg)
        end

        def labels_layer
          Labels.new(diagram, canvas: canvas, model_index: model_index,
                      theme: theme, document: document).render
        end

        def ghost_labels_layer
          GhostLabels.new(diagram, canvas: canvas).render
        end

        def merge_layers_by_style(layers)
          merged = {}
          layers.each do |layer|
            if merged[layer.style_key]
              merged[layer.style_key] = Layer.new(
                style_key: layer.style_key,
                style: layer.style,
                body: "#{merged[layer.style_key].body}\n  #{layer.body}"
              )
            else
              merged[layer.style_key] = layer
            end
          end
          merged.values
        end
      end
    end
  end
end
