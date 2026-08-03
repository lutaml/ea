# frozen_string_literal: true

module Ea
  module Qea
    module Models
      # Role-based constraint from t_roleconstraint.
      class EaRoleConstraint < BaseModel
        attribute :roleconstraint_id, :integer
        attribute :ea_object_id, :integer
        attribute :role, :string
        attribute :notes, :string

        def self.primary_key_column
          :roleconstraint_id
        end

        def self.table_name
          "t_roleconstraint"
        end

        COLUMN_MAP = {
          "RoleConstraintID" => :roleconstraint_id,
          "Object_ID" => :ea_object_id
        }.freeze

        def self.column_map
          COLUMN_MAP
        end
      end
    end
  end
end
