# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      module Emitters
        # Emits `<ownedAttribute uml:Property>` for a t_attribute row.
        #
        # Output shape (when all data present):
        #
        #   <ownedAttribute xmi:type="uml:Property" xmi:id="..." name="..."
        #       visibility="..." type="...">
        #     <lowerValue xmi:type="uml:LiteralInteger" .../>
        #     <upperValue xmi:type="uml:LiteralUnlimitedNatural" .../>
        #     <defaultValue xmi:type="uml:LiteralString" .../>
        #   </ownedAttribute>
        #
        # Multiplicity bounds come from the row's `lowerbound` and
        # `upperbound` fields. EA stores them as strings like "1" or "*";
        # this emitter normalizes "*" to the UML `-1` (unlimited).
        class AttributeEmitter < BaseEmitter
          UNLIMITED_TOKENS = %w[* *-1 unbounded].freeze

          def emit(attribute, ctx)
            ctx.writer.owned_attribute(
              xmi_id: ctx.xmi_id_for(attribute),
              name: attribute.name,
              visibility: visibility_for(attribute),
              type: type_ref(attribute),
              is_static: attribute.static?,
            ) do
              emit_multiplicity(attribute, ctx)
              emit_default(attribute, ctx)
            end
          end

          private

          def visibility_for(attribute)
            return attribute.scope.downcase unless attribute.scope.nil? || attribute.scope.empty?

            "private"
          end

          # Resolve the attribute's type to an xmi:idref. EA stores the type as
          # a name (e.g. "xs:string" or "ClassA"). For Phase 1, we emit a
          # synthesized `EAnone_<name>` identifier matching Sparx convention
          # for unresolved types — this round-trips cleanly through the xmi
          # gem's Sparx parser.
          def type_ref(attribute)
            type_name = attribute.type
            return nil if type_name.nil? || type_name.empty?

            classifier = attribute.classifier
            return GuidFormat.ea_guid_to_xmi_id(classifier) if classifier

            "EAnone_#{type_name}"
          end

          def emit_multiplicity(attribute, ctx)
            lower = attribute.lowerbound
            upper = attribute.upperbound
            return if lower.nil? && upper.nil?

            ctx.writer.lower_value(
              xmi_id: multiplicity_id(attribute, :lower, ctx),
              value: normalize_lower(lower),
            ) if lower
            ctx.writer.upper_value(
              xmi_id: multiplicity_id(attribute, :upper, ctx),
              value: normalize_upper(upper),
            ) if upper
          end

          def emit_default(attribute, ctx)
            return if attribute.default.nil? || attribute.default.empty?

            ctx.writer.default_value(
              xmi_id: ctx.id_allocator.allocate(
                prefix: IdAllocator::OPAQUE_EXPRESSION,
                seed: "default-#{attribute.id}",
              ),
              value: attribute.default,
            )
          end

          def normalize_lower(raw)
            raw.to_s
          end

          def normalize_upper(raw)
            UNLIMITED_TOKENS.include?(raw.to_s.strip.downcase) ? "-1" : raw.to_s
          end

          def multiplicity_id(attribute, side, ctx)
            ctx.id_allocator.for_multiplicity(
              side,
              seed: "mult-#{attribute.id}-#{side}",
            )
          end
        end
      end
    end
  end
end
