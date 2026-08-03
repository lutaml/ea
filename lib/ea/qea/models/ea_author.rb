# frozen_string_literal: true

module Ea
  module Qea
    module Models
      # Author / contributor from t_authors.
      #
      # Schema:
      #   (AuthorID INTEGER PRIMARY KEY, Name TEXT, Email TEXT,
      #    Notes TEXT, ...)
      class EaAuthor < BaseModel
        attribute :author_id, :integer
        attribute :name, :string
        attribute :email, :string
        attribute :notes, :string

        def self.primary_key_column
          :author_id
        end

        def self.table_name
          "t_authors"
        end

        COLUMN_MAP = {
          "AuthorID" => :author_id
        }.freeze

        def self.column_map
          COLUMN_MAP
        end
      end
    end
  end
end