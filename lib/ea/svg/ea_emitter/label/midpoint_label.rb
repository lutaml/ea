# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Label
        # Renders the midpoint label for a connector. EA emits one
        # of two things at the midpoint, but not both:
        #
        #   1. «stereotype» when the relationship has an applied
        #      stereotype (e.g. «import», «realize»).
        #   2. The relationship's Name when no stereotype is applied
        #      and Name is non-empty (e.g. "Association A").
        #
        # Stereotype wins when both are present.
        class MidpointLabel
          attr_reader :canvas, :model_index, :font_family, :font_size,
                      :font_unit

          def initialize(canvas:, model_index:, font_family:, font_size:,
                         font_unit:)
            @canvas = canvas
            @model_index = model_index
            @font_family = font_family
            @font_size = font_size
            @font_unit = font_unit
          end

          # Returns the SVG `<text>` for the connector's midpoint
          # label, or nil if there is no label to render.
          def text_for(connector, points)
            content = midpoint_content(connector)
            return nil if content.nil?

            mx, my = midpoint(points)
            render_text(mx, my, content)
          end

          # Returns the formatted «stereotype» string or nil. Used
          # by Label::Registry to dispatch end-label vs midpoint.
          def stereotype_label(connector)
            rel = relationship_for(connector)
            return nil unless rel

            stereotype = rel.stereotype
            return nil if stereotype.nil? || stereotype.to_s.empty?

            "«#{stereotype}»"
          end

          # Returns the midpoint label content: stereotype if
          # present, else the relationship Name.
          def midpoint_content(connector)
            stereotype = stereotype_label(connector)
            return stereotype if stereotype

            rel = relationship_for(connector)
            return nil unless rel

            name = rel.name
            return nil if name.nil? || name.to_s.empty?

            name.to_s
          end

          def relationship_for(connector)
            return nil unless model_index

            rel = model_index[connector.relationship_ref]
            return nil unless rel.is_a?(Ea::Model::Relationship)

            rel
          end

          private

          def midpoint(points)
            mid_idx = points.size / 2
            if points.size.odd?
              points[mid_idx]
            else
              a = points[mid_idx - 1]
              b = points[mid_idx]
              [(a[0] + b[0]) / 2, (a[1] + b[1]) / 2]
            end
          end

          def render_text(x, y, content)
            x_t = canvas ? canvas.translate_x(x) : x
            y_t = canvas ? canvas.translate_y(y) : y
            TextRenderer.new(content:, x: x_t, y: y_t,
                             family: font_family, size: font_size,
                             size_unit: font_unit,
                             fill: "#000000",
                             text_length: content.length * 6).to_svg
          end
        end
      end
    end
  end
end
