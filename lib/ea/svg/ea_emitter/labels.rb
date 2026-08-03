# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Emits the labels layer: connector role/multiplicity end
      # labels plus midpoint stereotype labels for non-association
      # connectors.
      #
      # This class is the orchestrator. The actual label-shaping
      # logic lives in dedicated, MECE collaborators under
      # `Ea::Svg::EaEmitter::Label`:
      #
      #   Label::EndLabel      - role + «property» + mult at LLT/LRT
      #   Label::MidpointLabel - «stereotype» at connector midpoint
      #   Label::Registry      - dispatch by relationship kind (OCP)
      #
      # Theme is read once and threaded to collaborators so the
      # rendering rules (font family/size, fill color) live in one
      # place.
      class Labels
        DEFAULT_FAMILY = "Yu Gothic UI"
        DEFAULT_SIZE = 13

        attr_reader :diagram, :canvas, :model_index, :theme, :document

        def initialize(diagram, canvas: nil, model_index: nil, theme: nil,
                       document: nil)
          @diagram = diagram
          @canvas = canvas
          @model_index = model_index
          @theme = theme || Ea::Theme::Registry.default
          @document = document
        end

        def render
          texts = visible_connectors.flat_map { |c| texts_for(c) }
          return "" if texts.empty?

          %(<g style="stroke-width:1;stroke-linecap:round;stroke-linejoin:bevel; fill:#000000;fill-opacity:1.00; stroke:#000000; stroke-opacity:0.00">\n#{texts.join("\n")}\n</g>)
        end

        private

        def visible_connectors
          (diagram.connectors || []).select(&:renderable?)
        end

        def texts_for(connector)
          points = waypoint_pairs(connector)
          return [] if points.size < 2

          texts = []

          # Midpoint label: stereotype «import», or relationship
          # Name ("Association A"). Renders at the path midpoint.
          mid_text = midpoint_renderer.text_for(connector, points)
          texts << mid_text if mid_text

          # End-labels: role name + «property» + multiplicity at
          # positioned LLT/LRT boxes. Only for associations without
          # a midpoint stereotype (stereotyped associations route
          # to midpoint only).
          if registry.end_label?(connector)
            end_label_texts(connector, points).each { |t| texts << t }
          end

          texts
        end

        def end_label_texts(connector, points)
          source_pt = points.first
          target_pt = points.last
          boxes = connector.label_boxes || {}

          texts = []
          end_renderer.texts(text_box: boxes[:llt], mult_box: boxes[:llb],
                             anchor: source_pt, connector: connector,
                             end_kind: :source).each { |t| texts << t }
          end_renderer.texts(text_box: boxes[:lrt], mult_box: boxes[:lrb],
                             anchor: target_pt, connector: connector,
                             end_kind: :target).each { |t| texts << t }
          texts
        end

        def registry
          @registry ||= Label::Registry.new(model_index: model_index)
        end

        def end_renderer
          @end_renderer ||= Label::EndLabel.new(
            canvas: canvas,
            model_index: model_index,
            document: document,
            theme: theme,
            font_family: label_font_family,
            font_size: label_font_size,
            font_unit: theme.font_size_unit
          )
        end

        def midpoint_renderer
          @midpoint_renderer ||= Label::MidpointLabel.new(
            canvas: canvas,
            model_index: model_index,
            font_family: label_font_family,
            font_size: label_font_size,
            font_unit: theme.font_size_unit
          )
        end

        def waypoint_pairs(connector)
          (connector.waypoints || []).filter_map do |w|
            next unless w.position

            [w.position.x, w.position.y]
          end
        end

        def label_font_family
          theme.font_family || DEFAULT_FAMILY
        end

        def label_font_size
          theme.font_size || DEFAULT_SIZE
        end
      end
    end
  end
end
