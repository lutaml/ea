# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      module Emitters
        # Emits `<packagedElement uml:Enumeration>` with one `<ownedLiteral>`
        # per enumeration value.
        #
        # EA stores enumeration values as child rows of the Enumeration object
        # in `t_attribute` (with `ea_object_id` = the enum's `ea_object_id`),
        # tagged by the loader as enum literals. This emitter reads them from
        # the same attribute index as {AttributeEmitter} but emits them as
        # literals.
        class EnumerationEmitter < BaseEmitter
          def self.kind = :enumeration

          def emit(object, ctx)
            ctx.writer.packaged_element(
              xmi_type: "uml:Enumeration",
              xmi_id: ctx.xmi_id_for(object),
              name: object.name,
            ) do
              emit_literals(object, ctx)
            end
          end

          private

          def emit_literals(object, ctx)
            sorted_by_position(ctx.attributes_for(object.ea_object_id)).each do |attr|
              next unless enum_literal?(attr)

              ctx.writer.owned_literal(
                xmi_id: ctx.xmi_id_for(attr),
                name: attr.name,
              )
            end
          end

          # EA t_attribute rows for an Enumeration can be either real
          # attributes (rare) or enumeration literals (common, identified by
          # the loader's classifier or stereotype). In the QEA loader,
          # enumeration literals are t_attribute rows whose parent classifier
          # has object_type "Enumeration" — they're indistinguishable from
          # regular attributes at this layer, so we treat all of them as
          # literals when the parent is an Enumeration.
          def enum_literal?(_attr)
            true
          end
        end
      end

      EmitterRegistry.register(:enumeration, Emitters::EnumerationEmitter.new)
    end
  end
end
