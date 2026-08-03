# frozen_string_literal: true

module Ea
  module Qea
    module Validation
      # Evaluates OCL invariants stored in t_objectconstraint.
      # For each constraint, parse its OCL expression via
      # Ea::Ocl::Parser and evaluate it against the owning
      # object's attribute values. Failures surface as :warning
      # messages — OCL failures aren't structural errors.
      class OclConstraintValidator < BaseValidator
        def validate
          constraints = database.collections[:object_constraints] || []
          constraints.each { |c| check_constraint(c) }
        end

        private

        def check_constraint(constraint)
          owner = owner_for(constraint)
          return unless owner

          ast = parse(constraint.constraint)
          return unless ast

          if evaluate(ast, owner)
            result.add_info(
              category: :ocl_constraint,
              entity_type: :class,
              entity_id: owner.ea_object_id.to_s,
              entity_name: owner.name,
              message: "OCL constraint '#{constraint.constraint_type}' passed",
            )
          else
            result.add_warning(
              category: :ocl_constraint,
              entity_type: :class,
              entity_id: owner.ea_object_id.to_s,
              entity_name: owner.name,
              message: "OCL constraint '#{constraint.constraint_type}' failed: #{constraint.constraint}",
            )
          end
        rescue Ea::Ocl::UnsupportedError => e
          result.add_info(
            category: :ocl_constraint,
            entity_type: :class,
            entity_id: owner&.ea_object_id.to_s,
            entity_name: owner&.name,
            message: "Skipping OCL constraint (unsupported syntax): #{e.message}",
          )
        end

        # Parse the OCL body. Returns nil for empty / non-invariant
        # constraints (we don't try to evaluate non-invariant forms).
        def parse(body)
          return nil if body.nil? || body.empty?

          Ea::Ocl::Parser.parse(body)
        end

        def evaluate(ast, owner)
          Ea::Ocl::Evaluator.evaluate(ast, owner)
        end

        def owner_for(constraint)
          object_id = constraint.ea_object_id
          return nil unless object_id

          (database.collections[:objects] || [])
            .find { |o| o.ea_object_id == object_id }
        end
      end
    end
  end
end
