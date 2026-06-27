# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      module Emitters
        # Emits `<ownedOperation>` with `<ownedParameter>` children for
        # operation parameters and return type.
        class OperationEmitter < BaseEmitter
          RETURN_KIND = "return"

          def emit(operation, ctx)
            ctx.writer.owned_operation(
              xmi_id: ctx.xmi_id_for(operation),
              name: operation.name,
              visibility: visibility_for(operation),
              is_static: operation.static?,
              is_abstract: operation.abstract?,
            ) do
              emit_parameters(operation, ctx)
              emit_return(operation, ctx)
            end
          end

          private

          def visibility_for(operation)
            return operation.scope.downcase unless operation.scope.nil? || operation.scope.empty?

            "private"
          end

          def emit_parameters(operation, ctx)
            sorted_by_position(ctx.params_for_operation(operation.operationid)).each do |param|
              next if param.return?

              ctx.writer.owned_parameter(
                xmi_id: ctx.xmi_id_for(param),
                name: param.name,
                type: type_ref(param),
                kind: param.kind&.downcase,
              )
            end
          end

          def emit_return(operation, ctx)
            return if operation.type.nil? || operation.type.empty?

            ctx.writer.owned_parameter(
              xmi_id: ctx.id_allocator.allocate(
                prefix: "RT",
                seed: "return-#{operation.operationid}",
              ),
              name: "return",
              type: "EAnone_#{operation.type}",
              kind: RETURN_KIND,
            )
          end

          def type_ref(param)
            return nil if param.type.nil? || param.type.empty?

            "EAnone_#{param.type}"
          end
        end
      end
    end
  end
end
