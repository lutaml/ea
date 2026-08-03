# frozen_string_literal: true

module Ea
  module Qea
    module Models
      # Requirement trace from t_objectrequires.
      class EaObjectRequire < BaseModel
        attribute :object_require_id, :integer
        attribute :object_id, :integer
        attribute :requirement, :string
        attribute :requirement_type, :string
        attribute :notes, :string

        def self.primary_key_column
          :object_require_id
        end

        def self.table_name
          "t_objectrequires"
        end

        COLUMN_MAP = {
          "ObjectReqID" => :object_require_id,
          "Object_ID" => :object_id,
          "ReqType" => :requirement_type
        }.freeze

        def self.column_map
          COLUMN_MAP
        end
      end
    end
  end
end
