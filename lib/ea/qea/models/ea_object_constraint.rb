# frozen_string_literal: true

module Ea
  module Qea
    module Models
      # EA Object Constraint model
      #
      # Represents OCL constraints attached to UML objects in the
      # t_objectconstraint table.
      #
      # @example Create from database row
      #   row = {
      #     "Object_ID" => 4,
      #     "Constraint" => "count(self.legalConstraints) >= 1",
      #     "ConstraintType" => "Invariant",
      #     "Weight" => "0.0",
      #     "Notes" => nil,
      #     "Status" => "Approved"
      #   }
      #   constraint = EaObjectConstraint.from_db_row(row)
      class EaObjectConstraint < BaseModel
        attribute :constraint_id, :integer
        attribute :ea_object_id, :integer
        attribute :constraint, :string
        attribute :constraint_type, :string
        attribute :weight, :float
        attribute :notes, :string
        attribute :status, :string

        # @return [Symbol] Primary key column name
        def self.primary_key_column
          :constraint_id
        end

        # @return [String] Database table name
        def self.table_name
          "t_objectconstraint"
        end


        COLUMN_MAP = {
          "ConstraintID" => :constraint_id,
          "Object_ID" => :ea_object_id,
          "ConstraintType" => :constraint_type,
        }.freeze

        def self.column_map
          COLUMN_MAP
        end
      end
    end
  end
end
