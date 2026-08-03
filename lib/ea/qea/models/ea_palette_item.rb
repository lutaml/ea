# frozen_string_literal: true

module Ea
  module Qea
    module Models
      # Toolbox item from t_paletteitem. Maps a stereotype/toolbox
      # entry to its visual icon and default toolbox slot.
      class EaPaletteItem < BaseModel
        attribute :palette_id, :string
        attribute :object_id, :integer
        attribute :name, :string
        attribute :alias, :string
        attribute :image_id, :integer
        attribute :notes, :string

        def self.primary_key_column
          :palette_id
        end

        def self.table_name
          "t_paletteitem"
        end

        COLUMN_MAP = {
          "PaletteID" => :palette_id,
          "Object_ID" => :object_id,
          "Image_ID" => :image_id
        }.freeze

        def self.column_map
          COLUMN_MAP
        end
      end
    end
  end
end
