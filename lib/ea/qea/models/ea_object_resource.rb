# frozen_string_literal: true

module Ea
  module Qea
    module Models
      # Resource allocation from t_objectresource.
      class EaObjectResource < BaseModel
        attribute :object_resource_id, :integer
        attribute :object_id, :integer
        attribute :resource, :string
        attribute :role, :string
        attribute :time_allocated, :string
        attribute :notes, :string

        def self.primary_key_column
          :object_resource_id
        end

        def self.table_name
          "t_objectresource"
        end

        COLUMN_MAP = {
          "ObjectResourceID" => :object_resource_id,
          "Object_ID" => :object_id
        }.freeze

        def self.column_map
          COLUMN_MAP
        end
      end
    end
  end
end
