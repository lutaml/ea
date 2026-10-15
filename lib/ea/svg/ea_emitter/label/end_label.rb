# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Label
        # Renders the role + «property» + multiplicity cluster at one
        # endpoint of a UML association connector.
        #
        # EA encodes end-labels in two geometry boxes per endpoint:
        #
        #   LLT/LRT - "label text" position (role name slot)
        #   LLB/LRB - "label box" position (multiplicity slot)
        #
        # Each box carries OX/OY offsets from the connector anchor.
        # The «property» stereotype renders one line below the role
        # name. EA records qualified role names ("pkg::role") for
        # cross-package associations but suppresses label rendering
        # for those — only simple role names render.
        class EndLabel
          PROPERTY_STEREOTYPE = "«Property»"
          SEAT_FONT_SIZE = 7
          SEAT_X_INSET = 3
          SEAT_STEREOTYPE_GAP = 12

          attr_reader :canvas, :model_index, :document, :theme,
                      :font_family, :font_size, :font_unit

          def initialize(canvas:, model_index:, document:, theme:,
                         font_family:, font_size:, font_unit:)
            @canvas = canvas
            @model_index = model_index
            @document = document
            @theme = theme
            @font_family = font_family
            @font_size = font_size
            @font_unit = font_unit
          end

          # Returns an Array of `<text>` SVG strings for one endpoint.
          #
          #   text_box   - LLT or LRT box geometry (role position)
          #   mult_box   - LLB or LRB box geometry (mult position)
          #   anchor     - [x, y] of the connector endpoint
          #   connector  - the DiagramConnector (for relationship lookup)
          #   end_kind   - :source or :target
          #   heading    - [dx, dy] of the first leg leaving the anchor
          #   stored_labels - the connector has stored label boxes at
          #                   either end; false keeps the opposite-end
          #                   fallback
          def texts(text_box:, mult_box:, anchor:, connector:, end_kind:,
                    tree: false, heading: nil, stored_labels: false)
            from_property, role, mult = role_and_multiplicity(connector, end_kind)
            if role_empty?(role) && mult_empty?(mult)
              other_from_prop, other_role, other_mult = role_and_multiplicity(connector,
                                                              opposite(end_kind))
              if stored_labels
                return [] if role_empty?(other_role) && mult_empty?(other_mult)

                return own_stereotype_only(text_box, anchor, connector,
                                           end_kind)
              end

              role = other_role if role_empty?(role)
              mult ||= other_mult
              from_property ||= other_from_prop
            end
            agg = aggregation_kind_for(connector, end_kind)
            standalone = standalone_multiplicity(role, mult, aggregation: agg)
            return [] if role_empty?(role) && (standalone.nil? || standalone.empty?)

            text_pos = position_at(text_box, anchor)
            mult_pos = position_at(mult_box, anchor) || text_pos
            if tree && zero_offset?(text_box, mult_box)
              text_pos, mult_pos = tree_positions(end_kind, anchor, role,
                                                  text_pos, mult_pos)
            elsif mult_box && stored_offsets_zero?(mult_box)
              # Start at the legacy default; measured directional seats
              # below replace it for default Cambria labels.
              mult_pos = [anchor[0] + 12, anchor[1] + 15]
            end
            # The end's stored stereotype renders verbatim («Type» on
            # 066E0FD1, «Property» on the Property ends); no line when
            # the end has none.
            stereo = connector_source_dest_stereotype(connector, end_kind)
            stereo = stereo.nil? || stereo.empty? ? nil : "«#{stereo}»"
            direction = leg_direction(end_kind, heading)
            if direction && !(tree && zero_offset?(text_box, mult_box))
              text_pos = source_property_seat(connector, direction, anchor, text_box, role) ||
                         plain_upward_seat(connector, direction, anchor, text_box, role) ||
                         role_seat(direction, anchor, text_box, role) || text_pos
              mult_pos = directional_multiplicity(connector, direction, anchor, mult_box, mult) ||
                         mult_seat(direction, anchor, mult_box) || mult_pos
            end

            build_texts(role:, mult:, standalone:,
                        text_pos:, mult_pos:, stereo:, text_box:)
          end

          private

          # With stored boxes on the connector, an end that carries no
          # data of its own draws only its own stereotype; the data end
          # draws the role and multiplicity; with no data anywhere nothing
          # is drawn. Connectors with no stored box keep the opposite-end
          # fallback.
          def own_stereotype_only(text_box, anchor, connector, end_kind)
            stereo = connector_source_dest_stereotype(connector, end_kind)
            pos = position_at(text_box, anchor)
            return [] if stereo.nil? || stereo.empty? || pos.nil?

            [text_at(pos[0], pos[1], "«#{stereo}»")]
          end

          # EA's tree-route label clusters (hand-verified against the
          # EA-published reference, SY 8542 with canvas=(0,0)):
          # source-end pairs stack at the exit point (role +3/-23,
          # mult +3/0); target-end pairs sit just above the dock
          # astride the trunk — role right edge at trunk+7, mult
          # starting at trunk+8, both at dock_y - 8.
          def stored_offsets_zero?(box)
            box["ox"].to_i.zero? && box["oy"].to_i.zero?
          end

          def zero_offset?(text_box, mult_box)
            [text_box, mult_box].compact.all? do |b|
              b["ox"].to_i.zero? && b["oy"].to_i.zero?
            end
          end

          def tree_positions(end_kind, anchor, role, text_pos, mult_pos)
            if end_kind == :source
              [[anchor[0] + 3, anchor[1] - 23],
               [anchor[0] + 3, anchor[1]]]
            else
              width = Ea::Fonts::Metrics.text_length(
                role.to_s, font_size, family: font_family
              ) || role.to_s.length * 6
              [[anchor[0] + 7 - width, anchor[1] - 8],
               [anchor[0] + 8, anchor[1] - 8]]
            end
          end

          # Stored source-end boxes on a 7pt label whose first leg
          # leaves straight up or straight right are seated at the box
          # corner, anchor + (OX, OY) with no sign flip, 3px to its
          # right: the multiplicity 6px above it on an upward leg and
          # 15px below it on a rightward one, the role 7px above it on
          # a rightward one. Other sizes, headings, the target end,
          # custom presentation keep their offsets. Zero multiplicity boxes
          # follow the direction for Cambria and keep the default otherwise.
          def leg_direction(end_kind, heading)
            return nil unless source_seat?(end_kind, heading)

            dx, dy = heading
            return :up if dx.zero? && dy.negative?
            return :right if dy.zero? && dx.positive?
            return :left if dy.zero? && dx.negative?
            return :down if dx.zero? && dy.positive?

            nil
          end

          # Role text on a rightward leg is left-aligned at the corner,
          # 7px above it.
          def role_seat(direction, anchor, box, role)
            return nil unless direction == :right
            return nil if box.nil? || role_empty?(role)
            return nil unless default_presentation?(box)

            x, y = seat_corner(anchor, box)
            [x + SEAT_X_INSET, y - 7]
          end

          # Property-role clusters use a direction-specific right edge;
          # alignment controls the stereotype line within that cluster.
          def source_property_seat(connector, direction, anchor, box, role)
            return nil unless %i[up left down].include?(direction) && property_role_box?(box, direction)
            return nil unless source_property_font?(connector, direction)

            width = Ea::Fonts::Metrics.text_length(role, font_size, family: font_family)
            return nil unless width

            x, y = seat_corner(anchor, box)
            inset, baseline = property_role_offsets(direction)
            [x - inset - width, y + baseline]
          end

          def plain_upward_seat(connector, direction, anchor, box, role)
            return nil unless direction == :up && cambria_box?(box)
            return nil unless [0, 1].include?(box["alignment"])
            return nil unless connector_source_dest_stereotype(connector, :source).empty?
            return nil unless plain_role_route?(connector.style.to_h)

            width = Ea::Fonts::Metrics.text_length(role, font_size, family: font_family)
            return nil unless width

            x, y = seat_corner(anchor, box)
            [x - SEAT_X_INSET - width, y - 6]
          end

          def plain_role_route?(style)
            %w[1 3].include?(style[:mode]) && %w[0 2].include?(style[:lwidth]) &&
              [nil, "V"].include?(style[:tree])
          end

          def property_role_box?(box, direction)
            alignments = direction == :down ? [1] : [0, 1]
            box && alignments.include?(box["alignment"]) && default_presentation?(box)
          end

          def property_role_offsets(direction)
            case direction
            when :up then [60, -6]
            when :left then [60, -7]
            else [65, 15]
            end
          end

          def source_property_font?(connector, direction)
            font_family.to_s.casecmp("Cambria").zero? &&
              property_label?(connector, :source) &&
              source_property_route?(connector.style.to_h, direction)
          end

          def source_property_route?(style, direction)
            case direction
            when :left then left_property_route?(style)
            when :down then downward_property_route?(style)
            else style[:lwidth] == "2" && style[:tree] != "OS"
            end
          end

          def left_property_route?(style)
            style[:mode] == "3" && %w[0 2].include?(style[:lwidth]) &&
              [nil, "H", "LV"].include?(style[:tree])
          end

          def downward_property_route?(style)
            %w[1 3].include?(style[:mode]) && style[:lwidth] == "2" && !style[:tree]
          end

          def directional_multiplicity(connector, direction, anchor, box, mult)
            return nil unless cambria_box?(box)

            x, y = seat_corner(anchor, box)
            return [x + 8, y + 15] if direction == :down
            return nil unless direction == :left && source_property_font?(connector, direction)

            width = Ea::Fonts::Metrics.text_length(mult, font_size, family: font_family)
            [x - width - 3, y + 15] if width
          end

          def cambria_box?(box)
            box && default_presentation?(box) && font_family.to_s.casecmp("Cambria").zero?
          end

          def mult_seat(direction, anchor, box)
            return nil unless %i[up right].include?(direction)
            return nil if box.nil?
            return nil if stored_offsets_zero?(box) && !cambria_box?(box)
            return nil unless default_presentation?(box)

            x, y = seat_corner(anchor, box)
            [x + SEAT_X_INSET, direction == :right ? y + 15 : y - 6]
          end

          def source_seat?(end_kind, heading)
            end_kind == :source && heading && seat_font?
          end

          def seat_font?
            font_size == SEAT_FONT_SIZE && font_unit == "pt"
          end

          # Boxes with explicit string-keyed OX/OY (the QEA shape) that
          # are unrotated, unhidden, unstyled and left/center aligned.
          def default_presentation?(box)
            return false unless box["ox"] && box["oy"]
            return false unless [nil, 0, 1].include?(box["alignment"])
            return false unless [nil, -1].include?(box["color"])

            box["rotation"].to_i.zero? && box["direction"].to_i.zero? &&
              box.values_at("hidden", "bold", "italic", "underline")
                 .none?
          end

          def seat_corner(anchor, box)
            [anchor[0] + box["ox"].to_i, anchor[1] + box["oy"].to_i]
          end

          def build_texts(role:, mult:, standalone:, text_pos:, mult_pos:,
                          stereo:, text_box:)
            if role && !role.empty? && text_pos
              x, y = text_pos
              texts = [text_at(x, y, role)]
              if stereo
                stereo_x = x + stereotype_offset(role, stereo, text_box)
                texts << text_at(stereo_x, y + property_y_offset(text_box), stereo)
              end
              if mult && !mult.empty? && mult_pos
                texts << text_at(*mult_pos, mult)
              end
              texts
            elsif standalone && !standalone.empty? && mult_pos
              [text_at(*mult_pos, standalone)]
            else
              []
            end
          end

          def stereotype_offset(role, stereo, text_box)
            return 0 unless text_box && text_box["alignment"] == 1

            role_width = TextRenderer.estimate_width(role, font_size,
                                                     family: font_family).round
            stereo_width = TextRenderer.estimate_width(stereo, font_size,
                                                       family: font_family).round
            ((role_width - stereo_width) / 2.0).round
          end

          # EA renders «Property» between role name and multiplicity
          # exactly on connector ends carrying
          # t_connector.SourceStereotype / DestStereotype = "Property"
          # (case-insensitive; stored variants include "property").
          # Direction does not decide — Fig 11's directed aggregations
          # carry no end stereotype and render none, while the CityGML
          # profile diagrams mark ends explicitly.
          PROPERTY_KEYWORD = "property"

          def connector_source_dest_stereotype(connector, end_kind)
            stereo = end_kind == :source ? connector.source_stereotype :
                       connector.target_stereotype
            stereo.to_s.strip
          end

          def property_label?(connector, end_kind)
            stereo = end_kind == :source ? connector.source_stereotype : connector.target_stereotype
            stereo.to_s.downcase == PROPERTY_KEYWORD
          end

          def role_empty?(role)
            role.nil? || role.empty?
          end

          def mult_empty?(mult)
            mult.nil? || mult.empty?
          end

          def opposite(end_kind)
            end_kind == :source ? :target : :source
          end

          def role_and_multiplicity(connector, end_kind)
            assoc = association_for(connector)
            return [nil, nil, nil] unless assoc

            prop = property_at_end(assoc, end_kind, connector)
            return [true, *property_role(prop)] if prop

            [false, *association_role(assoc, end_kind)]
          end

          def property_at_end(association, end_kind, connector = nil)
            # EA renders the source classifier's synthesized
            # association-end property (matched by the connector's
            # relationship guid), falling back to the property index
            # lookup by association source/target id.
            if connector&.relationship_ref
              placed = placed_classifier_id(association, end_kind)
              prop = assoc_end_property(placed, connector.relationship_ref)
              return prop if prop
            end

            id = end_kind == :source ? association.source_id : association.target_id
            return nil unless id

            return document.property_by_id(id) if document

            fallback_property_lookup(id)
          end

          def placed_classifier_id(association, end_kind)
            end_kind == :source ? association.source_id : association.target_id
          end

          # Find the synthesized association-end property on the
          # placed classifier whose association_id matches the
          # connector's relationship reference.
          def assoc_end_property(classifier_id, relationship_ref)
            return nil unless classifier_id

            classifier = model_index[classifier_id]
            return nil unless classifier.is_a?(Ea::Model::Classifier)

            (classifier.properties || []).find do |p|
              p.association_id == relationship_ref
            end
          end

          # Linear-scan fallback for callers that did not wire in
          # the Document. Production paths go through Document's
          # property_index for O(1) lookup.


          def fallback_property_lookup(id)
            return nil unless model_index

            model_index.each_value do |obj|
              next unless obj.is_a?(Ea::Model::Classifier)

              found = (obj.properties || []).find { |p| p.id == id }
              return found if found
            end
            nil
          end

          def property_role(property)
            visibility = visibility_prefix(property)
            name = property.name.to_s
            type_name = property.type_name.to_s
            line = if type_name.empty? || type_name == " "
                     "#{visibility}#{name}"
                   else
                     "#{visibility}#{name}: #{namespace_double_colon(type_name)}"
                   end
            role = line.empty? ? nil : line
            mult = multiplicity_text(property)
            [role, mult]
          end

          def namespace_double_colon(type_name)
            return type_name if type_name.nil? || type_name.empty?

            type_name.to_s.gsub(/([A-Za-z0-9_]):([A-Za-z])/, '\1::\2')
          end

          def association_role(assoc, end_kind)
            name = end_kind == :source ? assoc.source_role_name : assoc.target_role_name
            raw = end_kind == :source ? assoc.source_multiplicity_raw : assoc.target_multiplicity_raw
            lower = end_kind == :source ? assoc.source_multiplicity_lower : assoc.target_multiplicity_lower
            upper = end_kind == :source ? assoc.source_multiplicity_upper : assoc.target_multiplicity_upper
            mult = raw && !raw.empty? ? raw : multiplicity_string(lower, upper)
            return [nil, mult] if name.to_s.include?("::")

            role = name.nil? || name.empty? ? nil : "+#{name}"
            [role, mult]
          end

          def association_for(connector)
            return nil unless model_index

            rel = model_index[connector.relationship_ref]
            return nil unless rel.is_a?(Ea::Model::Association)

            rel
          end

          # Returns the aggregation kind for the given end (:shared,
          # :composite, or nil). An aggregation marker on the OPPOSITE
          # end means THIS end is the "part" end of an aggregation —
          # EA shows "1" multiplicity for such ends.
          def aggregation_kind_for(connector, end_kind)
            assoc = association_for(connector)
            return nil unless assoc

            opposite_kind = opposite(end_kind)
            agg = opposite_kind == :source ? assoc.source_aggregation : assoc.target_aggregation
            return nil if agg.nil? || agg == "none"

            agg.to_sym
          end

          def position_at(box, anchor)
            return nil unless box

            offset_x = box["ox"] || box[:ox]
            offset_y = box["oy"] || box[:oy]
            return nil if offset_x.nil? && offset_y.nil?

            # Waypoint anchors are mirrored to screen-down space; the
            # stored OY offset counts the other way, so negate it.
            [anchor[0] + offset_x.to_i, anchor[1] - offset_y.to_i]
          end

          # The stereotype line sits 12px below the role on 7pt labels
          # with default presentation;
          # other sizes and custom presentation keep size + 6.
          def property_y_offset(text_box)
            return SEAT_STEREOTYPE_GAP if seat_font? && text_box &&
                                          default_presentation?(text_box)

            font_size + 6
          end

          def multiplicity_text(property)
            raw = property.multiplicity_raw
            return raw if raw && !raw.empty?

            multiplicity_string(property.multiplicity_lower,
                                property.multiplicity_upper)
          end

          def multiplicity_string(lower, upper)
            return nil if lower.nil? && upper.nil?
            return "1" if lower == 1 && upper == 1

            upper_str = upper == -1 ? "*" : upper.to_s
            "#{lower || 0}..#{upper_str}"
          end

          # EA suppresses standalone multiplicity when it is
          # unspecified (nil). Explicit multiplicity renders
          # regardless of aggregation kind. The QEA parser now
          # returns nil for absent SourceCard/DestCard so default
          # "1" is no longer produced — only explicit "1" reaches
          # this method.
          def standalone_multiplicity(role, mult, aggregation: nil)
            return nil if role && !role.empty?
            return nil if mult.nil?

            mult
          end

          def visibility_prefix(property)
            VisibilitySymbol.for(property.visibility)
          end

          def text_at(x, y, content)
            return nil if content.nil? || content.empty?

            x_t = canvas ? canvas.translate_x(x) : x
            y_t = canvas ? canvas.translate_y(y) : y
            TextRenderer.new(content:, x: x_t, y: y_t,
                             family: font_family, size: font_size,
                             size_unit: font_unit,
                             fill: fill_color).to_svg
          end

          def fill_color
            "#000000"
          end
        end
      end
    end
  end
end
