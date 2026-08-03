# frozen_string: true

module Ea
  module Export
    module PlantUml
      # Generates PlantUML class diagram text from a parsed QEA model.
      #
      # Emits:
      # - Package nesting (`package "X" { ... }`)
      # - Class declarations with attributes and operations
      # - Generalizations (`Parent <|-- Child`)
      # - Associations with multiplicities and role names
      # - Enumerations as `enum` blocks
      class Generator
        def self.call(model, **_opts)
          new(model).call
        end

        attr_reader :model

        def initialize(model)
          @model = model
        end

        def call
          lines = ["@startuml", "skinparam classAttributeIconSize 0"]
          lines.concat(package_lines)
          lines.concat(connector_lines)
          lines << "@enduml"
          lines.join("\n") + "\n"
        end

        private

        # Wrap classes/enums in their containing packages.
        def package_lines
          packages_by_id = packages_index
          root_objects = (model.collections[:objects] || [])

          # Group classes by their package_id; emit each package.
          grouped = root_objects.group_by(&:package_id)
          grouped.flat_map do |pkg_id, objs|
            next ungrouped_lines(objs) if pkg_id.nil?

            pkg = packages_by_id[pkg_id]
            pkg_name = pkg&.name || "Package#{pkg_id}"
            inner = objs.flat_map { |o| class_block(o) }
            next inner if inner.empty?

            ["package \"#{pkg_name}\" {",
             *inner.map { |line| "  #{line}" },
             "}"]
          end.compact
        end

        def ungrouped_lines(objs)
          objs.flat_map { |o| class_block(o) }
        end

        # Emit `class X { +attr: T ... }` or `enum X { LITERAL1 ... }`.
        def class_block(obj)
          case obj.object_type
          when "Class"
            attrs = class_attributes(obj)
            body = attrs.map { |a| "+#{a.name}: #{a.type || 'String'}" }
            return ["class #{obj.name}"] if body.empty?

            ["class #{obj.name} {", *body.map { |b| "  #{b}" }, "}"]
          when "Enumeration"
            literals = enum_literals(obj)
            return ["enum #{obj.name}"] if literals.empty?

            ["enum #{obj.name} {",
             *literals.map { |l| "  #{l.name || l}" },
             "}"]
          when "Interface"
            ["interface #{obj.name}"]
          when "DataType"
            ["abstract class #{obj.name}"]
          else
            ["class #{obj.name}"]
          end
        end

        # Generalizations: `<|`-style inheritance.
        # Associations: multiplicity + role names.
        def connector_lines
          (model.collections[:connectors] || []).filter_map do |conn|
            src = find_object(conn.start_object_id)
            tgt = find_object(conn.end_object_id)
            next nil unless src && tgt

            case conn.connector_type
            when "Generalization"
              "#{tgt.name} <|-- #{src.name}"
            when "Association", "Aggregation", "Composition"
              assoc_arrow(src, tgt, conn)
            else
              label = conn.name ? " : #{conn.name}" : ""
              "#{src.name} --> #{tgt.name}#{label}"
            end
          end
        end

        def assoc_arrow(src, tgt, conn)
          arrow = case conn.connector_type
                  when "Composition" then "*--"
                  when "Aggregation" then "o--"
                  else "--"
                  end
          label = conn.name ? " : #{conn.name}" : ""
          "#{src.name} #{arrow} #{tgt.name}#{label}"
        end

        def packages_index
          (model.collections[:packages] || []).each_with_object({}) do |p, acc|
            acc[p.package_id] = p
          end
        end

        def class_attributes(klass)
          attrs = model.collections[:attributes] || []
          attrs.select { |a| a.ea_object_id == klass.ea_object_id }
        end

        def enum_literals(enum)
          literals = model.collections[:enumeration_literals] ||
                     model.collections[:enum_literals] || []
          literals.select do |literal|
            literal.is_a?(Ea::Qea::Models::EaAttribute) &&
              literal.ea_object_id == enum.ea_object_id
          end
        end

        def find_object(object_id)
          (model.collections[:objects] || [])
            .find { |o| o.ea_object_id == object_id || o.object_id == object_id }
        end
      end
    end
  end
end
