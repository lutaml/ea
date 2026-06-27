# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      module Emitters
        # Emits `<interfaceRealization>` inside the implementing class,
        # referencing the implemented interface.
        class RealizationEmitter < BaseEmitter
          def emit(connector, ctx)
            supplier = ctx.object_by_id(connector.end_object_id)
            return unless supplier

            ctx.writer.implementation(
              xmi_id: ctx.xmi_id_for(connector),
              supplier_id: ctx.xmi_id_for(supplier),
            )
          end
        end
      end
    end
  end
end
