# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      module Emitters
        # Emits `<packagedElement uml:Association>` from a t_connector row.
        #
        # Output shape:
        #
        #   <packagedElement xmi:type="uml:Association" xmi:id="EAID_<conn>">
        #     <memberEnd xmi:idref="EAID_dst<conn>"/>
        #     <ownedEnd xmi:type="uml:Property" xmi:id="EAID_dst<conn>" ...
        #         association="EAID_<conn>">
        #       <type xmi:idref="EAID_<dest_obj>"/>
        #       <lowerValue .../>
        #       <upperValue .../>
        #     </ownedEnd>
        #     <memberEnd xmi:idref="EAID_src<conn>"/>
        #     <ownedEnd xmi:type="uml:Property" xmi:id="EAID_src<conn>" ...
        #         association="EAID_<conn>">
        #       <type xmi:idref="EAID_<src_obj>"/>
        #     </ownedEnd>
        #   </packagedElement>
        class AssociationEmitter < BaseEmitter
          def self.kind = :association

          def emit(connector, ctx)
            ctx.writer.packaged_element(
              xmi_type: "uml:Association",
              xmi_id: ctx.xmi_id_for(connector),
              name: connector.name,
            ) do
              emit_end(connector, ctx, side: :destination)
              emit_end(connector, ctx, side: :source)
            end
          end

          private

          def emit_end(connector, ctx, side:)
            end_id = end_xmi_id(connector, ctx, side: side)
            target_obj = target_object(connector, ctx, side: side)
            target_ref = target_obj ? ctx.xmi_id_for(target_obj) : nil

            ctx.writer.member_end(xmi_id_ref: end_id)
            ctx.writer.owned_end(
              xmi_id: end_id,
              name: role_name(connector, side),
              association: ctx.xmi_id_for(connector),
              aggregation: aggregation_kind(connector, side),
            ) do
              if target_ref
                ctx.writer.type_reference(xmi_id_ref: target_ref)
              end
              emit_multiplicity(connector, ctx, side)
            end
          end

          def end_xmi_id(connector, ctx, side:)
            ctx.end_xmi_id_for(ctx.xmi_id_for(connector), side: side)
          end

          def target_object(connector, ctx, side:)
            target_id = side == :source ? connector.start_object_id : connector.end_object_id
            ctx.object_by_id(target_id)
          end

          def role_name(connector, side)
            side == :source ? connector.sourcerole : connector.destrole
          end

          def aggregation_kind(connector, side)
            is_aggregate = side == :source ? connector.source_aggregate? : connector.dest_aggregate?
            is_composite = composite?(connector, side)
            return "composite" if is_composite
            return "shared"   if is_aggregate

            nil
          end

          # Composition vs Aggregation: EA distinguishes them by the
          # connector_type field. Both end up as UML aggregation="shared" or
          # "composite" depending on which side holds the diamond.
          def composite?(connector, side)
            return false unless connector.connector_type == "Composition"

            # Diamond is on the side that owns the parts (the composite parent).
            # EA stores Composition with the composite at the source by
            # convention.
            side == :source
          end

          def emit_multiplicity(connector, ctx, side)
            card = side == :source ? connector.sourcecard : connector.destcard
            bounds = parse_cardinality(card)
            return unless bounds

            ctx.writer.lower_value(
              xmi_id: ctx.id_allocator.for_multiplicity(
                :lower, seed: "mult-#{connector.connector_id}-#{side}-lower",
              ),
              value: bounds[:lower],
            ) if bounds[:lower]
            ctx.writer.upper_value(
              xmi_id: ctx.id_allocator.for_multiplicity(
                :upper, seed: "mult-#{connector.connector_id}-#{side}-upper",
              ),
              value: bounds[:upper],
            ) if bounds[:upper]
          end

          # EA cardinality format: ".." separated bounds, e.g. "1..*", "0..1".
          # Single number means exact (e.g. "1" → lower=upper=1).
          def parse_cardinality(raw)
            return nil if raw.nil? || raw.to_s.empty?

            stripped = raw.to_s.strip
            return parse_range(stripped) if stripped.include?("..")

            single = normalize_bound(stripped)
            { lower: single, upper: single }
          end

          def parse_range(stripped)
            lower, upper = stripped.split("..", 2)
            { lower: normalize_bound(lower), upper: normalize_bound(upper) }
          end

          def normalize_bound(token)
            return "-1" if token.nil? || token.strip.empty?
            return "-1" if token.strip == "*"

            token.strip
          end
        end
      end

      EmitterRegistry.register(:association, Emitters::AssociationEmitter.new)
    end
  end
end
