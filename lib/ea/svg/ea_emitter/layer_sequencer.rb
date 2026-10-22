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

        # Emitted once per sequencer: the canvas, diagram and options
        # are fixed at construction, so a re-layout builds a new
        # sequencer rather than re-emitting this one.
        def layers
          @layers ||= build_layers.freeze
        end

        # Final drawn Bounds per model element ref (grown heights,
        # autosized packages) captured by the element pass; connector
        # emission re-docks direct lines against these.
        def drawn_bounds
          @elements&.drawn_bounds
        end

        # Row-slot seating stays off. Elements records each divider in canvas
        # space, so it only matched logical connector ends when the canvas
        # origin was 0 (the content-anchored default) and then moved one end
        # 13 px in all four corpus cases it matched (5D6DB5A0 Aggregation and
        # Generalization, ADC8773C, F46E8F19), none of which EA seats on a
        # row; it never matched an XMI route. Under the framed canvas it was
        # inert, which is the behaviour native parity was measured against.
        def divider_y_by_ref
          nil
        end

        # Right edge of the connector end-label boxes, model coordinates.
        def label_reach
          @labels&.reach
        end

        private

        def build_layers
          layers = [Background.render(canvas)]
          layers += frame_layers if frame_enabled
          layers += element_layers
          layers += connector_layers
          layers << labels_layer
          layers << ghost_labels_layer
          layers
        end

        def frame_layers
          DiagramFrame.new(canvas: canvas, theme: theme).layers(diagram).map(&:to_svg)
        end

        def element_layers
          @elements = Elements.new(diagram, model_index: model_index,
                                             canvas: canvas,
                                             document: document)
          @elements.groups
        end

        # EA paints connector by connector: each line is followed by
        # its own heads, and only adjacent same-style groups merge.
        def connector_layers
          lines = Connectors.new(diagram, canvas: canvas,
                                          grouped: true,
                                          stroke_width: DEFAULT_STROKE_WIDTH,
                                          drawn_bounds: drawn_bounds,
                                          divider_y_by_ref: divider_y_by_ref,
                                          model_index: model_index).connector_layers
          markers = Markers.new(diagram, model_index: model_index,
                                         canvas: canvas, grouped: true,
                                         stroke_width: DEFAULT_STROKE_WIDTH,
                                         drawn_bounds: drawn_bounds,
                                         divider_y_by_ref: divider_y_by_ref).connector_layers
          by_owner = {}.compare_by_identity
          (lines + markers).each { |owner, layer| (by_owner[owner] ||= []) << layer }
          ordered = PaintOrder.connectors(diagram).flat_map { |connector| by_owner.fetch(connector, []) }
          merge_adjacent_by_style(ordered).map(&:to_svg)
        end

        def labels_layer
          @labels = Labels.new(diagram, canvas: canvas, model_index: model_index,
                              theme: theme, document: document,
                              drawn_bounds: drawn_bounds,
                              divider_y_by_ref: divider_y_by_ref)
          @labels.render
        end

        def ghost_labels_layer
          GhostLabels.new(diagram, canvas: canvas).render
        end

        def merge_adjacent_by_style(layers)
          layers.each_with_object([]) do |layer, merged|
            last = merged.last
            if last && last.style_key == layer.style_key
              merged[-1] = Layer.new(style_key: last.style_key, style: last.style,
                                     body: "#{last.body}\n  #{layer.body}")
            else
              merged << layer
            end
          end
        end
      end
    end
  end
end
