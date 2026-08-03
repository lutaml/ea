# frozen_string_literal: true

module Ea
  module Qea
    module Models
      # Risk register entry from t_objectrisks.
      class EaObjectRisk < BaseModel
        attribute :object_risk_id, :integer
        attribute :object_id, :integer
        attribute :risk, :string
        attribute :risk_type, :string
        attribute :notes, :string

        def self.primary_key_column
          :object_risk_id
        end

        def self.table_name
          "t_objectrisks"
        end

        COLUMN_MAP = {
          "ObjectRiskID" => :object_risk_id,
          "Object_ID" => :object_id,
          "RiskType" => :risk_type
        }.freeze

        def self.column_map
          COLUMN_MAP
        end
      end
    end
  end
end
