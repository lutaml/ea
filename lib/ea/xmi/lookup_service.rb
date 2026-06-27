# frozen_string_literal: true

module Ea
  module Xmi
    # Bridge between Liquid Drop classes and the XMI parser.
    # Drops receive an instance of this service to look up XMI elements.
    class LookupService
      def initialize(parser)
        @parser = parser
      end

      def doc_node_attribute_value(node_id, attr_name)
        @parser.doc_node_attribute_value(node_id, attr_name)
      end

      def lookup_entity_name(xmi_id)
        @parser.lookup_entity_name(xmi_id)
      end

      def lookup_attribute_documentation(xmi_id)
        @parser.lookup_attribute_documentation(xmi_id)
      end

      def find_upper_level_packaged_element(klass_id)
        @parser.find_upper_level_packaged_element(klass_id)
      end

      def find_packaged_element_by_id(id)
        @parser.find_packaged_element_by_id(id)
      end

      def get_ns_by_xmi_id(xmi_id)
        @parser.get_ns_by_xmi_id(xmi_id)
      end

      def lookup_assoc_def(association)
        @parser.lookup_assoc_def(association)
      end

      def fetch_connector(link_id)
        @parser.fetch_connector(link_id)
      end

      def fetch_definition_node_value(link_id, node_name)
        @parser.fetch_definition_node_value(link_id, node_name)
      end

      def select_dependencies_by_supplier(supplier_id)
        @parser.select_dependencies_by_supplier(supplier_id)
      end

      def select_dependencies_by_client(client_id)
        @parser.select_dependencies_by_client(client_id)
      end

      def select_all_packaged_elements(all_elements, model, type)
        @parser.select_all_packaged_elements(all_elements, model, type)
      end

      def find_subtype_of_from_generalization(id)
        @parser.find_subtype_of_from_generalization(id)
      end

      def find_subtype_of_from_owned_attribute_type(id)
        @parser.find_subtype_of_from_owned_attribute_type(id)
      end

      def get_package_name(package)
        @parser.get_package_name(package)
      end

      def xmi_index
        @parser.xmi_index
      end

      def find_matched_element(xmi_id)
        xmi_index&.find_element(xmi_id)
      end

      def xmi_root_model
        @parser.xmi_root_model
      end

      def id_name_mapping
        @parser.id_name_mapping
      end
    end
  end
end
