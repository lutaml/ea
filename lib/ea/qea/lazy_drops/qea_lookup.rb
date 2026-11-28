# frozen_string_literal: true

module Ea
  module Qea
    module LazyDrops
      # LookupService-compatible cross-reference facade over the
      # Ea::Qea::Database indexes. Answers the methods the
      # Xmi-model-shaped Liquid drops call on options[:lookup], using
      # the database's own rows instead of a Sparx document graph.
      class QeaLookup
        # Read-only connector reference exposing the idref/name/
        # source/target surface ConnectorDrop and SourceTargetDrop
        # consume.
        ConnectorRef = Struct.new(:idref, :name, :documentation,
                                  :source, :target, keyword_init: true)

        Documentation = Struct.new(:value, keyword_init: true)

        Endpoint = Struct.new(:idref, keyword_init: true) do
          def documentation_value
            documentation&.value
          end
        end

        Endpoint = Struct.new(:idref, keyword_init: true)

        # Read-only dependency reference exposing the name/client/
        # supplier surface DependencyDrop consumes.
        DependencyRef = Struct.new(:name, :client, :supplier, keyword_init: true)

        def initialize(database)
          @database = database
          @names = nil
        end

        # xmi_id -> element name, the id_name_map equivalent.
        def id_name_mapping
          names
        end

        def lookup_entity_name(xmi_id)
          names[xmi_id]
        end

        # The name of the package directly containing the element.
        def find_upper_level_packaged_element(klass_id)
          object = object_by_xmi_id(klass_id)
          return object_package_name(object) if object

          package = package_by_xmi_id(klass_id)
          parent_name_for(package)
        end

        def find_packaged_element_by_id(_id)
          nil
        end

        def get_ns_by_xmi_id(xmi_id)
          object = object_by_xmi_id(xmi_id)
          return object_package_name(object) if object

          package = package_by_xmi_id(xmi_id)
          parent_name_for(package)
        end

        def get_package_name(package)
          package&.name
        end

        # Sparx-shaped connector reference for the drop surface.
        def fetch_connector(link_id)
          conn = database.connectors.find do |c|
            Ea::GuidFormat.ea_guid_to_xmi_id(c.ea_guid) == link_id
          end
          return nil unless conn

          ConnectorRef.new(
            idref: link_id,
            name: conn.name,
            documentation: documentation(conn.notes),
            source: endpoint(conn.start_object_id),
            target: endpoint(conn.end_object_id)
          )
        end

        def lookup_assoc_def(association)
          conn = connector_by_xmi_id(association)
          conn ? Ea::Rtf.to_text(conn.notes.to_s) : nil
        end

        def lookup_connector_def_by_associationclass(_association)
          nil
        end

        def fetch_definition_node_value(link_id, node_name)
          return unless node_name.to_s == "documentation"

          conn = connector_by_xmi_id(link_id)
          conn ? Ea::Rtf.to_text(conn.notes.to_s) : nil
        end

        # Dependency connectors whose supplier (end) or client (start)
        # resolves to the given element xmi id.
        def select_dependencies_by_supplier(supplier_id)
          dependencies.select { |dep| dep.supplier == supplier_id }
        end

        def select_dependencies_by_client(client_id)
          dependencies.select { |dep| dep.client == client_id }
        end

        # The parent (general) name behind a generalization link:
        # the generalization connector's end object name.
        def find_subtype_of_from_generalization(id)
          conn = connector_by_xmi_id(id)
          return nil unless conn&.generalization?

          parent = @database.find_object(conn.end_object_id)
          parent&.name
        end

        def find_subtype_of_from_owned_attribute_type(_id)
          nil
        end

        # Stereotype lookups read the object's stored stereotype.
        def doc_node_attribute_value(node_id, attr_name)
          return nil unless attr_name.to_s == "stereotype"

          object = object_by_xmi_id(node_id)
          object&.stereotype
        end

        def lookup_attribute_documentation(_xmi_id)
          nil
        end

        # The XMI-path links graph has no QEA equivalent.
        def find_matched_element(_xmi_id)
          nil
        end

        def xmi_root_model
          nil
        end

        def xmi_index
          self
        end

        private

        attr_reader :database

        def names
          @names ||= begin
            map = {}
            database.objects.all.each do |object|
              next unless object.ea_guid

              map[Ea::GuidFormat.ea_guid_to_xmi_id(object.ea_guid)] = object.name
            end
            database.packages.each do |package|
              next unless package.ea_guid

              map[Ea::GuidFormat.ea_guid_to_xmi_id(package.ea_guid)] = package.name
            end
            map
          end
        end

        def object_by_xmi_id(xmi_id)
          database.objects.all.find do |object|
            object.ea_guid &&
              Ea::GuidFormat.ea_guid_to_xmi_id(object.ea_guid) == xmi_id
          end
        end

        def package_by_xmi_id(xmi_id)
          database.packages.find do |package|
            package.ea_guid &&
              Ea::GuidFormat.ea_guid_to_xmi_id(package.ea_guid) == xmi_id
          end
        end

        def connector_by_xmi_id(xmi_id)
          database.connectors.find do |conn|
            conn.ea_guid &&
              Ea::GuidFormat.ea_guid_to_xmi_id(conn.ea_guid) == xmi_id
          end
        end

        def dependencies
          database.connectors
                  .select { |c| c.connector_type == "Dependency" }
                  .map do |conn|
            DependencyRef.new(
              name: conn.name,
              client: endpoint(conn.start_object_id)&.idref,
              supplier: endpoint(conn.end_object_id)&.idref
            )
          end
        end

        def endpoint(object_id)
          object = database.find_object(object_id)
          return nil unless object&.ea_guid

          Endpoint.new(idref: Ea::GuidFormat.ea_guid_to_xmi_id(object.ea_guid))
        end

        def object_package_name(object)
          package = database.find_package(object.package_id)
          package&.name
        end

        def parent_name_for(package)
          return nil unless package

          parent = database.find_package(package.parent_id)
          parent&.name
        end

        def documentation(notes)
          return nil if notes.nil? || notes.empty?

          Documentation.new(value: Ea::Rtf.to_text(notes.to_s))
        end
      end
    end
  end
end
