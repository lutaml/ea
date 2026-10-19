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
                      :font_unit, :font_weight, :font_style

          def initialize(canvas:, model_index:, font_family:, font_size:,
                         font_unit:, font_weight: 400, font_style: "normal")
            @canvas = canvas
            @model_index = model_index
            @font_family = font_family
            @font_size = font_size
            @font_unit = font_unit
            @font_weight = font_weight
            @font_style = font_style
          end

          # Returns the SVG `<text>` for the connector's midpoint
          # label, or nil if there is no label to render.
          def text_for(connector, points)
            content = midpoint_content(connector)
            return nil if content.nil?

            mx, my = label_position(connector, points)
            # EA splits a "name: value" label at the colon-space into
            # two lines centered on the same slot (81F92FC7: "new
            # ownership:" / "LA_Right" at y 172/185, both centered on
            # x=480).
            if (idx = content.index(": ")) && content.length > idx + 2
              return [
                render_text(mx, my, content[0..idx]),
                render_text(mx, my + LINE_PITCH, content[(idx + 2)..])
              ].join("\n")
            end

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
            # Generalizations carrying EA's isSubstitutable
            # CustomProperty draw the constraint at the label seat.
            if connector.respond_to?(:is_substitutable) &&
               connector.is_substitutable &&
               stereotype_label(connector).nil?
              return "{isSubstitutable=false}"
            end

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

          LINE_PITCH = 13

          def label_position(connector, points)
            stored_seat = stored_stereotype_position(connector, points) || stored_name_position(connector, points)
            return stored_seat if stored_seat

            return midpoint(points) unless default_substitutable_seat?(connector) &&
                                           upward_four_point_route?(points)

            source, bend = points
            [source[0] + 3, ((source[1] + bend[1]) / 2).floor - 1]
          end

          # LMB is the row below the midpoint; LMT carries the name above it.
          def stored_stereotype_position(connector, points)
            return nil unless connector.is_a?(Ea::Model::DiagramConnector) && measured_name_font?
            return nil unless stereotype_label(connector)

            box = connector.label_boxes.to_h[:lmb]
            return nil unless default_name_box?(box, alignments: [0, 1])

            stored_position(connector, points, box, LINE_PITCH)
          end

          # At 7pt, a centered name's stored corner is 3px below its baseline.
          def stored_name_position(connector, points)
            seat_points = horizontal_bend_seat(points) || points
            stored_position(connector, seat_points, stored_name_box(connector, points), -3)
          end

          def stored_position(connector, points, box, baseline)
            return nil unless box

            width = Ea::Fonts::Metrics.text_length(midpoint_content(connector), font_size, family: font_family)
            return nil unless width

            x, y = midpoint(points)
            offset_x, offset_y = box.values_at("ox", "oy").map(&:to_i)
            [x + offset_x - (width / 2.0).floor, y + offset_y + baseline]
          end

          def stored_name_box(connector, points)
            return nil unless connector.is_a?(Ea::Model::DiagramConnector) && measured_name_font?
            return nil if connector.is_substitutable || stereotype_label(connector)
            return nil if midpoint_content(connector).include?(": ")

            box = connector.label_boxes.to_h[:lmt]
            alignments = name_box_alignments(points)
            box if default_name_box?(box, alignments: alignments)
          end

          def name_box_alignments(points)
            horizontal_bend_seat(points) ? [0, 1] : [1]
          end

          # A vertical-to-horizontal bend seats its name on the horizontal leg.
          def horizontal_bend_seat(points)
            return nil unless points.size == 3

            source, bend, target = points
            return nil unless source[0] == bend[0] && source[1] != bend[1] &&
                              bend[1] == target[1] && bend[0] != target[0]

            [bend, target]
          end

          def measured_name_font?
            font_family.to_s.casecmp("Cambria").zero? && font_size == 7 && font_unit == "pt"
          end

          def default_name_box?(box, alignments: [1])
            return false unless box && alignments.include?(box["alignment"])
            return false unless box.values_at("ox", "oy").all?
            return false unless [nil, 0, 1].include?(box["direction"]) && [nil, -1].include?(box["color"])

            box["rotation"].to_i.zero? && box.values_at("bold", "italic", "underline", "hidden").none?
          end

          def default_substitutable_seat?(connector)
            connector.is_a?(Ea::Model::DiagramConnector) && connector.is_substitutable &&
              connector.connector_type == "Generalization" && font_size == 7 &&
              stereotype_label(connector).nil? &&
              default_constraint_box?(connector.label_boxes.to_h[:lmb])
          end

          def default_constraint_box?(box)
            box && !box["hidden"] &&
              box.values_at("ox", "oy", "rotation", "alignment") == [0, 0, 0, 0]
          end

          def upward_four_point_route?(points)
            return false unless points.size == 4

            source, first_bend, last_bend, target = points
            source[0] == first_bend[0] && first_bend[1] == last_bend[1] &&
              last_bend[0] == target[0] && source[1] > first_bend[1] &&
              target[1] < last_bend[1]
          end

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
                             weight: font_weight, style: font_style,
                             size_unit: font_unit,
                             fill: "#000000").to_svg
          end
        end
      end
    end
  end
end
