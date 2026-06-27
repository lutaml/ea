# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      module Emitters
        # Emits a `<slot>` for an instance specification's attribute value.
        # Called from {InstanceEmitter} for each attribute that has a default
        # value on the instance.
        class SlotEmitter < BaseEmitter
          def emit(attribute, ctx)
            return unless attribute.default

            ctx.writer.slot(
              xmi_id: ctx.id_allocator.allocate(
                prefix: IdAllocator::SLOT,
                seed: "slot-#{attribute.id}",
              ),
              defining_feature_id: ctx.xmi_id_for(attribute),
            ) do
              ctx.writer.opaque_expression_value(
                xmi_id: ctx.id_allocator.allocate(
                  prefix: IdAllocator::OPAQUE_EXPRESSION,
                  seed: "slot-value-#{attribute.id}",
                ),
                body: attribute.default,
              )
            end
          end
        end
      end
    end
  end
end
