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
          PROPERTY_STEREOTYPE = "«property»"

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
          def texts(text_box:, mult_box:, anchor:, connector:, end_kind:)
            from_property, role, mult = role_and_multiplicity(connector, end_kind)
            if role_empty?(role) && mult_empty?(mult)
              other_from_prop, other_role, other_mult = role_and_multiplicity(connector,
                                                              opposite(end_kind))
              role = other_role if role_empty?(role)
              mult ||= other_mult
              from_property ||= other_from_prop
            end
            agg = aggregation_kind_for(connector, end_kind)
            standalone = standalone_multiplicity(role, mult, aggregation: agg)
            return [] if role_empty?(role) && (standalone.nil? || standalone.empty?)

            text_pos = position_at(text_box, anchor)
            mult_pos = position_at(mult_box, anchor) || text_pos
            show_property = property_label?(connector)

            build_texts(role:, mult:, standalone:,
                        text_pos:, mult_pos:, show_property:)
          end

          private

          def build_texts(role:, mult:, standalone:, text_pos:, mult_pos:,
                          show_property:)
            if role && !role.empty? && text_pos
              x, y = text_pos
              texts = [text_at(x, y, role)]
              if show_property
                texts << text_at(x, y + property_y_offset, PROPERTY_STEREOTYPE)
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

          # EA renders «property» between role name and multiplicity
          # ONLY for directed associations/aggregations — those with
          # t_connector.Direction set to "Source -> Destination" or
          # "Destination -> Source". "Unspecified" / "Bi-Directional"
          # connectors do NOT get the stereotype label.
          #
          # Verified against both QEAs (output by the same EA in the
          # same run):
          #   - basic.qea: 4 Associations with Direction="Unspecified"
          #     and role+mult → 0 «property» labels.
          #   - plateau QEA: aggregations with Direction="Destination
          #     -> Source" → «property» rendered (737 instances across
          #     137 diagrams).
          UNDIRECTED_DIRECTIONS = %w[Unspecified Bi-Directional].freeze

          def property_label?(connector)
            direction = connector.direction.to_s
            return false if direction.empty?
            return false if UNDIRECTED_DIRECTIONS.include?(direction)

            true
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

            prop = property_at_end(assoc, end_kind)
            return [true, *property_role(prop)] if prop

            [false, *association_role(assoc, end_kind)]
          end

          def property_at_end(association, end_kind)
            id = end_kind == :source ? association.source_id : association.target_id
            return nil unless id

            return document.property_by_id(id) if document

            fallback_property_lookup(id)
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
            role = name.empty? ? nil : "#{visibility}#{name}"
            mult = multiplicity_text(property)
            [role, mult]
          end

          def association_role(assoc, end_kind)
            name = end_kind == :source ? assoc.source_role_name : assoc.target_role_name
            lower = end_kind == :source ? assoc.source_multiplicity_lower : assoc.target_multiplicity_lower
            upper = end_kind == :source ? assoc.source_multiplicity_upper : assoc.target_multiplicity_upper
            return [nil, multiplicity_string(lower, upper)] if name.to_s.include?("::")

            role = name.nil? || name.empty? ? nil : "+#{name}"
            mult = multiplicity_string(lower, upper)
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

            [anchor[0] + offset_x.to_i, anchor[1] + offset_y.to_i]
          end

          def property_y_offset
            font_size + 6
          end

          def multiplicity_text(property)
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
                             fill: fill_color,
                             text_length: content.length * 6).to_svg
          end

          def fill_color
            "#000000"
          end
        end
      end
    end
  end
end
