# frozen_string_literal: true

module Ea
  module Qea
    module Models
      # Object problem record from t_objectproblems.
      class EaObjectProblem < BaseModel
        attribute :object_problem_id, :integer
        attribute :object_id, :integer
        attribute :problem, :string
        attribute :problem_type, :string
        attribute :date_resolved, :string
        attribute :version, :string
        attribute :notes, :string

        def self.primary_key_column
          :object_problem_id
        end

        def self.table_name
          "t_objectproblems"
        end

        COLUMN_MAP = {
          "ObjectProblemID" => :object_problem_id,
          "Object_ID" => :object_id,
          "ProblemType" => :problem_type,
          "DateResolved" => :date_resolved
        }.freeze

        def self.column_map
          COLUMN_MAP
        end
      end
    end
  end
end
