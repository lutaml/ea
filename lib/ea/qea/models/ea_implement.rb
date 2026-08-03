# frozen_string_literal: true

module Ea
  module Qea
    module Models
      # UML-to-code mapping hint from t_implement.
      class EaImplement < BaseModel
        attribute :implement_id, :integer
        attribute :object_id, :integer
        attribute :language, :string
        attribute :code, :string

        def self.primary_key_column
          :implement_id
        end

        def self.table_name
          "t_implement"
        end

        COLUMN_MAP = {
          "ImplementID" => :implement_id,
          "Object_ID" => :object_id
        }.freeze

        def self.column_map
          COLUMN_MAP
        end
      end
    end
  end
end
