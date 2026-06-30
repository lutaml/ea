# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      module Emitters
        # Emits `<packagedElement uml:Dependency>` referencing client and
        # supplier objects.
        class DependencyEmitter < BaseEmitter
          def self.kind = :dependency

          def emit(connector, ctx)
            client = ctx.object_by_id(connector.start_object_id)
            supplier = ctx.object_by_id(connector.end_object_id)
            return unless client && supplier

            ctx.writer.dependency(
              xmi_id: ctx.xmi_id_for(connector),
              supplier_id: ctx.xmi_id_for(supplier),
            )
          end
        end
      end

      EmitterRegistry.register(:dependency, Emitters::DependencyEmitter.new)
    end
  end
end
