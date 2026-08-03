# frozen_string_literal: true

module Ea
  module Qea
    module Models
      # Test case from t_objecttests.
      class EaObjectTest < BaseModel
        attribute :object_test_id, :integer
        attribute :object_id, :integer
        attribute :test, :string
        attribute :test_type, :string
        attribute :status, :string
        attribute :notes, :string

        def self.primary_key_column
          :object_test_id
        end

        def self.table_name
          "t_objecttests"
        end

        COLUMN_MAP = {
          "ObjectTestID" => :object_test_id,
          "Object_ID" => :object_id,
          "TestType" => :test_type
        }.freeze

        def self.column_map
          COLUMN_MAP
        end
      end
    end
  end
end
