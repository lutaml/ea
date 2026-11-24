# frozen_string_literal: true

module Ea
  module Xmi
    # Bridge between Liquid Drop classes and the XMI parser.
    # Drops receive an instance of this service to look up XMI elements.
    # Shared per serialization run, so it also memoizes the O(elements)
    # dependency and guidance indexes that drops would otherwise rebuild
    # per class.
    class LookupService
      def initialize(parser, guidance = nil)
        @parser = parser
        @guidance = guidance
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

      def lookup_connector_def_by_associationclass(xmi_id)
        @parser.lookup_connector_def_by_associationclass(xmi_id)
      end

      def fetch_connector(link_id)
        @parser.fetch_connector(link_id)
      end

      def fetch_definition_node_value(link_id, node_name)
        @parser.fetch_definition_node_value(link_id, node_name)
      end

      def select_dependencies_by_supplier(supplier_id)
        dependencies_by_supplier[supplier_id] || []
      end

      def select_dependencies_by_client(client_id)
        dependencies_by_client[client_id] || []
      end

      # Guidance entry for a class by its name or absolute path.
      # @return [Hash, nil]
      def klass_guidance_for(name, absolute_path)
        klass_guidance_index[name] || klass_guidance_index[absolute_path]
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

      private

      def dependencies_by_supplier
        @dependencies_by_supplier ||= build_dependency_index(&:supplier)
      end

      def dependencies_by_client
        @dependencies_by_client ||= build_dependency_index(&:client)
      end

      def build_dependency_index(&key)
        index = {}
        parser.xmi_index
              .packaged_elements_of_type("uml:Dependency")
              .each do |dep|
          (index[key.call(dep)] ||= []) << dep
        end
        index
      end

      def klass_guidance_index
        @klass_guidance_index ||=
          Array(@guidance && @guidance["classes"]).each_with_object({}) do |entry, index|
            index[entry["name"]] = entry
          end
      end
    end
  end
end
