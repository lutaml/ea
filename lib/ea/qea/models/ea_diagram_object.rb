# frozen_string_literal: true

module Ea
  module Qea
    module Models
      # Represents a diagram object from the t_diagramobjects table
      #
      # This model represents the placement of UML elements (classes, packages,
      # etc.) on specific diagrams, including their position and styling.
      class EaDiagramObject < BaseModel
        attribute :diagram_id, Lutaml::Model::Type::Integer
        attribute :ea_object_id, Lutaml::Model::Type::Integer
        attribute :recttop, Lutaml::Model::Type::Integer
        attribute :rectleft, Lutaml::Model::Type::Integer
        attribute :rectright, Lutaml::Model::Type::Integer
        attribute :rectbottom, Lutaml::Model::Type::Integer
        attribute :sequence, Lutaml::Model::Type::Integer
        attribute :objectstyle, Lutaml::Model::Type::String
        attribute :instance_id, Lutaml::Model::Type::Integer

        def self.primary_key_column
          :instance_id
        end

        def self.table_name
          "t_diagramobjects"
        end


        COLUMN_MAP = {
          "Object_ID" => :ea_object_id,
        }.freeze

        def self.column_map
          COLUMN_MAP
        end

        # Get the bounding box of the diagram object
        # @return [Hash] Hash with :top, :left, :right, :bottom, :width, :height
        def bounding_box
          {
            top: recttop,
            left: rectleft,
            right: rectright,
            bottom: rectbottom,
            width: rectright - rectleft,
            height: rectbottom - recttop,
          }
        end

        # Get the center point of the diagram object
        # @return [Hash] Hash with :x, :y coordinates
        def center_point
          {
            x: (rectleft + rectright) / 2,
            y: (recttop + rectbottom) / 2,
          }
        end

        # Parse ObjectStyle string into a hash
        # @return [Hash] Parsed style attributes
        def parsed_style
          return {} unless objectstyle

          objectstyle.split(";").each_with_object({}) do |pair, hash|
            key, value = pair.split("=", 2)
            hash[key] = value if key && value
          end
        end
      end
    end
  end
end
