# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      module Emitters
        # Emits `<packagedElement uml:DataType>` or
        # `<packagedElement uml:PrimitiveType>` based on the EA object type.
        class DataTypeEmitter < BaseEmitter
          def self.kind = :data_type

          def emit(object, ctx)
            ctx.writer.packaged_element(
              xmi_type: xmi_type_for(object),
              xmi_id: ctx.xmi_id_for(object),
              name: object.name,
            ) do
              emit_attributes(object, ctx)
              emit_operations(object, ctx)
            end
          end

          private

          def xmi_type_for(object)
            primitive?(object) ? "uml:PrimitiveType" : "uml:DataType"
          end

          # EA represents primitive types (xs:string, xs:int, ...) as DataType
          # objects whose classifier_guid / pdata1 hints "primitive". For
          # Phase 1, only DataType/PrimitiveType object types are routed here;
          # the loader tags them. We treat them as PrimitiveType when the
          # object's `gentype` is "Java" or "primitive" — heuristic but
          # matches the loader's classification.
          def primitive?(object)
            object.object_type == "PrimitiveType" ||
              object.gentype == "Java" && object.stereotype_is?("primitive")
          end

          def emit_attributes(object, ctx)
            sorted_by_position(ctx.attributes_for(object.ea_object_id)).each do |attr|
              AttributeEmitter.new.emit(attr, ctx)
            end
          end

          def emit_operations(object, ctx)
            sorted_by_position(ctx.operations_for(object.ea_object_id)).each do |op|
              OperationEmitter.new.emit(op, ctx)
            end
          end
        end
      end

      EmitterRegistry.register(:data_type, Emitters::DataTypeEmitter.new)
    end
  end
end
