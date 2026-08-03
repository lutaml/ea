# frozen_string_literal: true

module Ea
  module Qea
    module Models
      # Transaction record from t_objecttrx.
      class EaObjectTrx < BaseModel
        attribute :object_trx_id, :integer
        attribute :object_id, :integer
        attribute :trx, :string
        attribute :trx_type, :string
        attribute :notes, :string

        def self.primary_key_column
          :object_trx_id
        end

        def self.table_name
          "t_objecttrx"
        end

        COLUMN_MAP = {
          "ObjectTrxID" => :object_trx_id,
          "Object_ID" => :object_id,
          "TrxType" => :trx_type
        }.freeze

        def self.column_map
          COLUMN_MAP
        end
      end
    end
  end
end
