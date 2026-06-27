# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      module Emitters
        # Emits `<packagedElement uml:InstanceSpecification>` for EA
        # "Object" rows (instance diagrams). Each instance carries a
        # `classifier` reference to its class and zero or more `<slot>`s
        # for attribute values.
        class InstanceEmitter < BaseEmitter
          def self.kind = :instance

          def emit(object, ctx)
            ctx.writer.packaged_element(
              xmi_type: "uml:InstanceSpecification",
              xmi_id: ctx.xmi_id_for(object),
              name: object.name,
              classifier: classifier_xmi_id(object, ctx),
            ) do
              emit_slots(object, ctx)
            end
          end

          private

          # An EA "Object" row's `classifier` column holds the ea_guid of the
          # referenced class. Translate it to that class's EAID.
          def classifier_xmi_id(object, ctx)
            return nil if object.classifier_guid.nil? || object.classifier_guid.empty?

            GuidFormat.ea_guid_to_xmi_id(object.classifier_guid)
          end

          def emit_slots(object, ctx)
            sorted_by_position(ctx.attributes_for(object.ea_object_id)).each do |attr|
              next unless attr.default

              SlotEmitter.new.emit(attr, ctx)
            end
          end
        end
      end

      EmitterRegistry.register(:instance, Emitters::InstanceEmitter.new)
    end
  end
end
