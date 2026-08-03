# frozen_string_literal: true

module Ea
  module Qea
    module Models
      # Enumeration list value from t_lists.
      #
      # Schema:
      #   (ListID TEXT PRIMARY KEY, Category TEXT, Name TEXT,
      #    NVal INTEGER, Notes TEXT)
      class EaList < BaseModel
        attribute :list_id, :string
        attribute :category, :string
        attribute :name, :string
        attribute :nval, :integer
        attribute :notes, :string

        def self.primary_key_column
          :list_id
        end

        def self.table_name
          "t_lists"
        end

        COLUMN_MAP = {
          "ListID" => :list_id,
          "NVal" => :nval
        }.freeze

        def self.column_map
          COLUMN_MAP
        end

        # @return [Boolean] true when this row carries a numeric value
        def numeric?
          !nval.nil?
        end
      end
    end
  end
end