# frozen_string: true

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
      def register(document)
        @documents.reject! { |d| d.technology_name == document.technology_name }
        @documents << document
      end

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
    end
  end
end
