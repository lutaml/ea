# frozen_string_literal: true

module Ea
  module Qea
    module Models
      # Use case scenario from t_objectscenarios.
      class EaObjectScenario < BaseModel
        attribute :object_scenario_id, :integer
        attribute :ea_object_id, :integer
        attribute :scenario, :string
        attribute :scenario_type, :string
        attribute :notes, :string

        def self.primary_key_column
          :object_scenario_id
        end

        def self.table_name
          "t_objectscenarios"
        end

        COLUMN_MAP = {
          "ObjectScenarioID" => :object_scenario_id,
          "Object_ID" => :ea_object_id,
          "ScenarioType" => :scenario_type
        }.freeze

        def self.column_map
          COLUMN_MAP
        end
      end
    end
  end
end
