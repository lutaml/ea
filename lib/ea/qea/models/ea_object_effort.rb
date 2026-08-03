# frozen_string_literal: true

module Ea
  module Qea
    module Models
      # Effort estimate from t_objecteffort.
      class EaObjectEffort < BaseModel
        attribute :object_effort_id, :integer
        attribute :object_id, :integer
        attribute :effort, :string
        attribute :effort_type, :string
        attribute :notes, :string

        def self.primary_key_column
          :object_effort_id
        end

        def self.table_name
          "t_objecteffort"
        end

        COLUMN_MAP = {
          "ObjectEffortID" => :object_effort_id,
          "Object_ID" => :object_id,
          "EffortType" => :effort_type
        }.freeze

        def self.column_map
          COLUMN_MAP
        end
      end
    end
  end
end
