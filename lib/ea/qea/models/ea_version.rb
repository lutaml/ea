# frozen_string_literal: true

module Ea
  module Qea
    module Models
      # Version control record from t_versions.
      #
      # Schema:
      #   (VersionID TEXT PRIMARY KEY, ElementID TEXT, Branch TEXT,
      #    VersionDate TEXT, Author TEXT, Notes TEXT, ...)
      class EaVersion < BaseModel
        attribute :version_id, :string
        attribute :element_id, :string
        attribute :branch, :string
        attribute :version_date, :string
        attribute :author, :string
        attribute :notes, :string

        def self.primary_key_column
          :version_id
        end

        def self.table_name
          "t_versions"
        end

        COLUMN_MAP = {
          "VersionID" => :version_id,
          "ElementID" => :element_id,
          "VersionDate" => :version_date
        }.freeze

        def self.column_map
          COLUMN_MAP
        end
      end
    end
  end
end