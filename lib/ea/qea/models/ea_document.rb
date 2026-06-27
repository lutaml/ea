# frozen_string_literal: true

module Ea
  module Qea
    module Models
      # Represents a document from the t_document table in EA database
      # Stores documentation style templates and artifacts
      class EaDocument < BaseModel
        attribute :doc_id, Lutaml::Model::Type::String
        attribute :doc_name, Lutaml::Model::Type::String
        attribute :doc_type, Lutaml::Model::Type::String
        attribute :str_content, Lutaml::Model::Type::String
        attribute :bin_content, Lutaml::Model::Type::String
        attribute :element_id, Lutaml::Model::Type::String

        def self.primary_key_column
          :doc_id
        end

        def self.table_name
          "t_document"
        end


        COLUMN_MAP = {
          "DocID" => :doc_id,
          "DocName" => :doc_name,
          "DocType" => :doc_type,
          "StrContent" => :str_content,
          "BinContent" => :bin_content,
          "ElementID" => :element_id,
        }.freeze

        def self.column_map
          COLUMN_MAP
        end

        # Convenience aliases
        alias_method :id, :doc_id
        alias_method :name, :doc_name
        alias_method :type, :doc_type

        # Check if this is a style document
        # @return [Boolean]
        def style_document?
          doc_type == "SSDOCSTYLE"
        end

        # Check if document has string content
        # @return [Boolean]
        def has_content?
          !str_content.nil? && !str_content.empty?
        end

        # Check if document has binary content
        # @return [Boolean]
        def has_binary_content?
          !bin_content.nil? && !bin_content.empty?
        end
      end
    end
  end
end
