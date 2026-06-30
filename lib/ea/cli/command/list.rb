# frozen_string_literal: true

module Ea
  module Cli
    module Command
      # `ea list FILE [--type TYPE]`
      #
      # Lists model elements from a QEA file. With `--type`, returns elements
      # of one kind (class/interface/package/diagram/connector/enum). Without
      # `--type`, returns a summary of counts per kind.
      #
      # Operates standalone — does not require lutaml-uml.
      class List < Base
        def call
          rows =
            if options[:type]
              list_by_type(options[:type])
            else
              list_summary
            end
          formatter.render(rows, columns: columns_for_current_mode)
        end

        private

        def list_summary
          db = load_database
          [
            [:classes,    db.objects.find_by_type("Class").size],
            [:interfaces, db.objects.find_by_type("Interface").size],
            [:packages,   db.packages.size],
            [:enums,      db.objects.find_by_type("Enumeration").size],
            [:datatypes,  db.objects.find_by_type("DataType").size],
            [:diagrams,   db.diagrams.size],
            [:connectors, db.connectors.size],
          ]
        end

        def list_by_type(type)
          db = load_database
          case type.to_s
          when "class"     then db.objects.find_by_type("Class").map { |o| [o.name, o.ea_guid] }
          when "interface" then db.objects.find_by_type("Interface").map { |o| [o.name, o.ea_guid] }
          when "enum"      then db.objects.find_by_type("Enumeration").map { |o| [o.name, o.ea_guid] }
          when "package"   then db.packages.map { |p| [p.name, p.ea_guid] }
          when "diagram"   then db.diagrams.map { |d| [d.name, d.ea_guid] }
          when "connector" then db.connectors.map { |c| [c.name, c.ea_guid] }
          else
            raise Ea::Cli::Error,
                  "Unknown type '#{type}'. " \
                  "Valid: class, interface, package, diagram, connector, enum"
          end
        end

        def columns_for_current_mode
          options[:type] ? %i[name guid] : %i[kind count]
        end
      end
    end
  end
end
