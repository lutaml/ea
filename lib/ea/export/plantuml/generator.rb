# frozen_string_literal: true

module Ea
  module Export
    module PlantUml
      # Generates PlantUML class diagram text from a parsed QEA model.
      #
      # Example output:
      #   @startuml
      #   class Person {
      #     +name: String
      #     +age: Integer
      #   }
      #   Person "1" --> "0..*" Address : lives_at
      #   @enduml
      class Generator
        def self.call(model, **_opts)
          new(model).call
        end

        attr_reader :model

        def initialize(model)
          @model = model
        end

        def call
          lines = ["@startuml"]
          lines.concat(class_lines)
          lines.concat(connector_lines)
          lines << "@enduml"
          lines.join("\n") + "\n"
        end

        private

        def class_lines
          classes.map do |klass|
            attrs = class_attributes(klass)
            body = attrs.map { |a| "  +#{a.name}: #{a.type || 'String'}" }
            ["class #{klass.name} {", *body, "}"].join("\n")
          end
        end

        def connector_lines
          (model.collections[:connectors] || []).map do |conn|
            source_obj = find_object(conn.start_object_id)
            target_obj = find_object(conn.end_object_id)
            next nil unless source_obj && target_obj

            label = conn.name ? " : #{conn.name}" : ""
            %Q{#{source_obj.name} --> #{target_obj.name}#{label}}
          end.compact
        end

        def classes
          (model.collections[:objects] || [])
            .select { |o| o.object_type == "Class" }
        end

        def class_attributes(klass)
          attrs = model.collections[:attributes] || []
          attrs.select { |a| a.object_id == klass.object_id }
        end

        def find_object(object_id)
          (model.collections[:objects] || [])
            .find { |o| o.object_id == object_id }
        end
      end
    end
  end
end
