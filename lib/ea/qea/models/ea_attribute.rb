# frozen_string_literal: true

module Ea
  module Qea
    module Models
      # Represents an attribute from the t_attribute table in EA database
      # This represents class attributes/properties
      class EaAttribute < BaseModel
        attribute :ea_object_id, Lutaml::Model::Type::Integer
        attribute :name, Lutaml::Model::Type::String
        attribute :scope, Lutaml::Model::Type::String
        attribute :stereotype, Lutaml::Model::Type::String
        attribute :containment, Lutaml::Model::Type::String
        attribute :isstatic, Lutaml::Model::Type::Integer
        attribute :iscollection, Lutaml::Model::Type::Integer
        attribute :isordered, Lutaml::Model::Type::Integer
        attribute :allowduplicates, Lutaml::Model::Type::Integer
        attribute :lowerbound, Lutaml::Model::Type::String
        attribute :upperbound, Lutaml::Model::Type::String
        attribute :container, Lutaml::Model::Type::String
        attribute :notes, Lutaml::Model::Type::String
        attribute :derived, Lutaml::Model::Type::String
        attribute :id, Lutaml::Model::Type::Integer
        attribute :pos, Lutaml::Model::Type::Integer
        attribute :genoption, Lutaml::Model::Type::String
        attribute :length, Lutaml::Model::Type::Integer
        attribute :precision, Lutaml::Model::Type::Integer
        attribute :scale, Lutaml::Model::Type::Integer
        attribute :const, Lutaml::Model::Type::Integer
        attribute :style, Lutaml::Model::Type::String
        attribute :classifier, Lutaml::Model::Type::String
        attribute :default, Lutaml::Model::Type::String
        attribute :type, Lutaml::Model::Type::String
        attribute :ea_guid, Lutaml::Model::Type::String
        attribute :styleex, Lutaml::Model::Type::String

        def self.primary_key_column
          :id
        end

        def self.table_name
          "t_attribute"
        end


        COLUMN_MAP = {
          "Object_ID" => :ea_object_id,
        }.freeze

        def self.column_map
          COLUMN_MAP
        end

        # Check if attribute is static
        # @return [Boolean]
        def static?
          isstatic == 1
        end

        # Check if attribute is a collection
        # @return [Boolean]
        def collection?
          iscollection == 1
        end

        # Check if attribute is ordered
        # @return [Boolean]
        def ordered?
          isordered == 1
        end

        # Check if attribute allows duplicates
        # @return [Boolean]
        def allow_duplicates?
          allowduplicates == 1
        end

        # Check if attribute is constant
        # @return [Boolean]
        def constant?
          const == 1
        end

        # Check if attribute is public
        # @return [Boolean]
        def public?
          scope&.downcase == "public"
        end

        # Check if attribute is private
        # @return [Boolean]
        def private?
          scope&.downcase == "private"
        end

        # Check if attribute is protected
        # @return [Boolean]
        def protected?
          scope&.downcase == "protected"
        end

        # @return [Integer] pos for attribute ordering within parent
        def sort_position
          pos || 0
        end
      end
    end
  end
end
