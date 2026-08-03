# frozen_string_literal: true

module Ea
  module Qea
    module Models
      # Glossary term from t_glossary.
      #
      # Schema:
      #   (Term TEXT, Type TEXT, Meaning TEXT, GlossaryID INTEGER PRIMARY KEY)
      class EaGlossary < BaseModel
        attribute :glossary_id, :integer
        attribute :term, :string
        attribute :type, :string
        attribute :meaning, :string

        def self.primary_key_column
          :glossary_id
        end

        def self.table_name
          "t_glossary"
        end

        COLUMN_MAP = {
          "GlossaryID" => :glossary_id
        }.freeze

        def self.column_map
          COLUMN_MAP
        end
      end
    end
  end
end