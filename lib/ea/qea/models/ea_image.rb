# frozen_string_literal: true

module Ea
  module Qea
    module Models
      # Raw-row model for `t_image`. EA stores pasted images as EMF
      # (Enhanced Metafile) blobs in this table.
      #
      # `type` values observed in real QEAs:
      #   - "ENHMetafile" — Enhanced Windows Metafile (most common)
      #   - "Metafile"    — Old-style WMF
      #   - "Bitmap"      — DIB / PNG bitmap
      class EaImage < BaseModel
        attribute :image_id, :integer
        attribute :name, :string
        attribute :type, :string
        attribute :image, :string

        def self.primary_key_column
          :image_id
        end

        def self.table_name
          "t_image"
        end

        COLUMN_MAP = {
          "ImageID" => :image_id
        }.freeze

        def self.column_map
          COLUMN_MAP
        end

        # @return [Boolean] true when this row holds an EMF blob
        def emf?
          type&.casecmp?("ENHMetafile")
        end

        # @return [Boolean] true when this row holds a WMF blob
        def wmf?
          type&.casecmp?("Metafile")
        end

        # Raw image bytes. SQLite returns BLOB as ASCII-8BIT String.
        # @return [String, nil] binary string
        def bytes
          image
        end
      end
    end
  end
end
