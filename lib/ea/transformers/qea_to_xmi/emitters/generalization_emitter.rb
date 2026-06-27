# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      module Emitters
        # Emits `<generalization general="<parent_eaid>"/>` inside the
        # subclass. Called from {ClassEmitter} — never directly from
        # {PackageEmitter} (generalizations are not packagedElements).
        class GeneralizationEmitter < BaseEmitter
          def emit(connector, ctx)
            parent = ctx.object_by_id(connector.end_object_id)
            return unless parent

            ctx.writer.generalization(
              xmi_id: ctx.xmi_id_for(connector),
              general_id: ctx.xmi_id_for(parent),
            )
          end
        end
      end
    end
  end
end
