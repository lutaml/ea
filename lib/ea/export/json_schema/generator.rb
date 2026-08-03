# frozen_string_literal: true

require "json"

module Ea
  module Export
    module JsonSchema
      # Generates a JSON Schema (draft 2020-12) document from a
      # parsed QEA model. Each UML Class becomes a `$defs` entry
      # with `properties` derived from its attributes.
      class Generator
        SCHEMA_URI = "https://json-schema.org/draft/2020-12/schema".freeze

        # EA primitive → JSON Schema type
        TYPE_MAP = {
          "int" => "integer", "Integer" => "integer",
          "long" => "integer", "Long" => "integer",
          "double" => "number", "Double" => "number",
          "float" => "number", "Float" => "number",
          "boolean" => "boolean", "Boolean" => "boolean",
          "String" => "string", "string" => "string",
          "char" => "string", "Character" => "string",
          "Date" => "string", "DateTime" => "string"
        }.freeze

        def self.call(model, **_opts)
          new(model).call
        end

        attr_reader :model

        def initialize(model)
          @model = model
        end

        def call
          classes = (model.collections[:objects] || [])
                     .select { |o| o.object_type == "Class" }
          defs = classes.each_with_object({}) do |klass, acc|
            acc[klass.name] = class_schema(klass)
          end

          {
            "$schema" => SCHEMA_URI,
            "$id" => "https://example.com/schema.json",
            "type" => "object",
            "$defs" => defs
          }.to_json
        end

        private

        def class_schema(klass)
          attrs = attribute_map[klass.object_id] || []
          {
            "type" => "object",
            "title" => klass.name,
            "properties" => attrs.each_with_object({}) do |a, props|
              props[a.name] = { "type" => json_type(a.type) }
            end
          }
        end

        def json_type(ea_type)
          TYPE_MAP[ea_type] || "string"
        end

        def attribute_map
          @attribute_map ||= begin
            attrs = model.collections[:attributes] || []
            attrs.group_by(&:object_id)
          end
        end
      end
    end
  end
end
