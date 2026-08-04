# frozen_string_literal: true

module Ea
  module Mdg
    # Multi-MDG lookup. Holds one or more loaded MDG Documents
    # and exposes a unified lookup surface (by name or by GUID)
    # that searches across all registered technologies.
    #
    # Source adapters OPTIONALLY accept an Mdg::Registry and use
    # it to resolve inherited attributes from MDG-defined parent
    # classes when a local Classifier's generalization parent
    # isn't in the local model.
    #
    # Example:
    #
    #   registry = Ea::Mdg::Registry.new
    #   registry.register(Ea::Mdg::Loader.from_path("MDG_ISO19103.xml"))
    #   registry.find_classifier_by_name("Any")         # → ClassifierEntry
    #   registry.inherited_properties_for("EAID_...")   # → [PropertyEntry, ...]
    class Registry
      include Enumerable

      attr_reader :documents

      def initialize
        @documents = []
      end

      # Register an MDG Document. Subsequent registrations of the
      # same technology_name replace the prior one (last-wins).
      #
      # Also registers the technology with
      # `Lutaml::Model::GlobalRegister` so it can be looked up via
      # the framework-level register API. This keeps MDG swapping
      # OCP-compliant: callers can query either Ea::Mdg::Registry
      # or Lutaml::Model::GlobalRegister to find loaded MDGs.
      def register(document)
        technology = document.technology_name
        @documents.reject! { |d| d.technology_name == technology }
        @documents << document
        register_with_lutaml(technology, document)
      end

      # Remove an MDG Document by technology name. Also unregisters
      # from Lutaml::Model::GlobalRegister.
      def unregister(technology_name)
        @documents.reject! { |d| d.technology_name == technology_name }
        lutaml_register_id = lutaml_id_for(technology_name)
        Lutaml::Model::GlobalRegister.remove(lutaml_register_id)
      end
      alias remove unregister

      def each(&block)
        @documents.each(&block)
      end

      def size
        @documents.size
      end

      def technology_names
        @documents.map(&:technology_name)
      end

      # Lookup by GUID across all registered technologies.
      def find_classifier_by_guid(guid)
        each do |doc|
          found = doc.find_by_guid(guid)
          return found if found
        end
        nil
      end

      # Lookup by name across all registered technologies. Returns
      # the first match (technologies are searched in registration
      # order).
      def find_classifier_by_name(name)
        each do |doc|
          found = doc.find_by_name(name)
          return found if found
        end
        nil
      end

      # Returns all Properties inherited from MDG ancestors of
      # the given classifier. The classifier's OWN properties
      # are excluded — only inherited MDG attributes are returned.
      #
      # Caller passes the local Classifier's EA GUID. The local
      # Classifier is looked up across all registered MDGs; if
      # found, its MDG ancestor chain is walked and each
      # ancestor's properties are collected in order.
      def inherited_properties_for(classifier_guid)
        result = []
        seen_property_names = {}

        each do |doc|
          classifier = doc.find_by_guid(classifier_guid)
          next unless classifier

          doc.ancestors_of(classifier_guid).each do |ancestor|
            (ancestor.properties || []).each do |prop|
              next if seen_property_names.key?(prop.name)

              seen_property_names[prop.name] = true
              result << prop
            end
          end
        end

        result
      end

      private

      # Registers the MDG with Lutaml::Model::GlobalRegister under a
      # stable, namespaced id. The register holds no model classes
      # directly (MDG stereotypes are domain concepts, not lutaml-model
      # types), but the registration makes the MDG discoverable via
      # the framework's standard register API.
      def register_with_lutaml(technology_name, _document)
        lutaml_register_id = lutaml_id_for(technology_name)
        register = Lutaml::Model::Register.new(lutaml_register_id)
        Lutaml::Model::GlobalRegister.register(register)
      end

      def lutaml_id_for(technology_name)
        :"ea_mdg_#{technology_name.to_s.downcase.gsub(/[^a-z0-9]/, "_")}"
      end
    end
  end
end
