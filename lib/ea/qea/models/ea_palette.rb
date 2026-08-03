# frozen_string_literal: true

module Ea
  module Qea
    module Models
      # Toolbox definition from t_palette.
      class EaPalette < BaseModel
        attribute :palette_id, :string
        attribute :name, :string
        attribute :technology, :string

        def self.primary_key_column
          :palette_id
        end

        def self.table_name
          "t_palette"
        end

        COLUMN_MAP = {
          "PaletteID" => :palette_id
        }.freeze

        def self.column_map
          COLUMN_MAP
        end
      end
    end
  end
end
