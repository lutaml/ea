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
            [:connectors, db.connectors.size]
          ]
        end

        # `ea list --type` keyword registries. Object types go through
        # EaObjectRepository#find_by_type; the rest map to Database
        # collections. Register new keywords here — no dispatch code
        # changes needed.
        OBJECT_TYPE_ALIASES = {
          "class" => "Class",
          "interface" => "Interface",
          "enum" => "Enumeration"
        }.freeze
        COLLECTION_ALIASES = {
          "package" => :packages,
          "diagram" => :diagrams,
          "connector" => :connectors
        }.freeze

        def list_by_type(type)
          db = load_database
          key = type.to_s
          return named_object_rows(db, OBJECT_TYPE_ALIASES.fetch(key)) if OBJECT_TYPE_ALIASES.key?(key)
          return collection_rows(db, COLLECTION_ALIASES.fetch(key)) if COLLECTION_ALIASES.key?(key)

          raise Ea::Cli::Error,
                "Unknown type '#{type}'. " \
                "Valid: #{(OBJECT_TYPE_ALIASES.keys + COLLECTION_ALIASES.keys).join(", ")}"
        end

        def named_object_rows(db, ea_type)
          db.objects.find_by_type(ea_type).map { |o| [o.name, o.ea_guid] }
        end

        def collection_rows(db, collection)
          db.public_send(collection).map { |r| [r.name, r.ea_guid] }
        end

        def columns_for_current_mode
          options[:type] ? %i[name guid] : %i[kind count]
        end
      end
    end
  end
end
