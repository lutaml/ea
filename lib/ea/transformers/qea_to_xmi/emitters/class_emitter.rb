# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      module Emitters
        # Emits `<packagedElement uml:Class>` with attributes, operations,
        # generalizations, and interface realizations owned by the class.
        class ClassEmitter < BaseEmitter
          def self.kind = :class

          def emit(object, ctx)
            ctx.writer.packaged_element(
              xmi_type: xmi_type_for(object),
              xmi_id: ctx.xmi_id_for(object),
              name: object.name,
              is_abstract: object.abstract?,
            ) do
              emit_generalizations(object, ctx)
              emit_realizations(object, ctx)
              emit_attributes(object, ctx)
              emit_operations(object, ctx)
            end
          end

          private

          def xmi_type_for(object)
            object.interface? ? "uml:Interface" : "uml:Class"
          end

          def emit_generalizations(object, ctx)
            inheritance_connectors(object, ctx).each do |conn|
              next unless conn.generalization?

              GeneralizationEmitter.new.emit(conn, ctx)
            end
          end

          def emit_realizations(object, ctx)
            inheritance_connectors(object, ctx).each do |conn|
              next unless conn.realization?

              RealizationEmitter.new.emit(conn, ctx)
            end
          end

          # Connectors where this object is on either side and the type is
          # Generalization or Realization. Generalization in EA: source is
          # the subclass, dest is the parent. Realization: source is the
          # implementer, dest is the interface.
          def inheritance_connectors(object, ctx)
            ctx.connectors_for(object.ea_object_id).select do |conn|
              source_end?(conn, object) && inheritance_type?(conn)
            end
          end

          def source_end?(conn, object)
            conn.start_object_id == object.ea_object_id
          end

          def inheritance_type?(conn)
            conn.generalization? || conn.realization?
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

      EmitterRegistry.register(:class, Emitters::ClassEmitter.new)
    end
  end
end
