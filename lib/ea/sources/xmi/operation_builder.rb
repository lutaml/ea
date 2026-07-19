# frozen_string_literal: true

module Ea
  module Sources
    module Xmi
      # Translates XMI OwnedOperation elements (with their
      # OwnedParameter children) into Ea::Model::Operation instances.
      class OperationBuilder
        def build_all_for(classifier)
          classifier.owned_operation.map { |op| build_one(op, classifier) }
        end

        def build_one(op, owner)
          id = IdNormalizer.from_xmi_id(op.id) ||
               IdNormalizer.synthetic_id(owner.id, "op", op.name)
          Ea::Model::Operation.new(
            id: id,
            name: op.name,
            owner_id: owner.id,
            qualified_name: "#{owner.name}::#{op.name}",
            return_type_name: return_type_name_for(op),
            visibility: op.visibility,
            is_static: boolean(op.is_static),
            is_abstract: boolean(op.is_abstract),
            parameters: build_parameters(op, id),
            annotations: AnnotationBuilder.from_element(op, id)
          )
        end

        private

        def build_parameters(op, owner_op_id)
          op.owned_parameter.map.with_index do |param, idx|
            direction = param.direction || (idx.zero? ? "return" : "in")
            Ea::Model::Parameter.new(
              id: IdNormalizer.from_xmi_id(param.id) ||
                  IdNormalizer.synthetic_id(owner_op_id, "param", idx.to_s),
              name: param.name || direction,
              ordinal: idx,
              direction: direction,
              type_name: param.type
            )
          end
        end

        def return_type_name_for(op)
          op.owned_parameter.find { |p| p.direction == "return" }&.type
        end

        def boolean(value)
          case value
          when true, "true" then true
          else false
          end
        end
      end
    end
  end
end
