# frozen_string: true

module Ea
  module Mdg
    # One MDG technology file's parsed model. Immutable container
    # carrying the technology's name, packages, classifiers,
    # stereotype definitions, and generalization relationships.
    #
    # Two MDG file formats are supported:
    #
    #   1. XMI format (UML:Model/UML:Class/...) — carries reference
    #      model classes with properties and generalizations.
    #   2. MDG.Technology format (<MDG.Technology>/<UMLProfiles>) —
    #      carries stereotype definitions with tagged-value specs.
    #
    # Both formats contribute to the same Document; stereotypes and
    # classifiers coexist without coupling.
    #
    # Lookups are O(1) via lazily-built hash indexes. Callers do
    # not mutate the Document.
    class Document
      ClassifierEntry = Struct.new(:id, :name, :package_name,
                                   :properties, keyword_init: true)
      PropertyEntry = Struct.new(:name, :type_name, :visibility,
                                 :multiplicity_lower,
                                 :multiplicity_upper,
                                 keyword_init: true)
      GeneralizationEntry = Struct.new(:specific_id, :general_id,
                                       keyword_init: true)
      # Stereotype definition from an MDG.Technology file.
      # Carries the stereotype's name, what element types it applies
      # to (Class, Package, Property, etc.), its tagged-value specs,
      # and any notes. `generalizes` links to a parent stereotype
      # when the MDG defines an inheritance chain between stereotypes.
      StereotypeEntry = Struct.new(:name, :applies_to, :tagged_values,
                                   :notes, :generalizes,
                                   :base_stereotypes,
                                   keyword_init: true)
      TaggedValueSpec = Struct.new(:name, :type, :description, :unit,
                                   :values, :default,
                                   keyword_init: true)

      attr_reader :technology_name, :classifiers, :generalizations,
                  :packages, :stereotypes

      def initialize(technology_name:, classifiers:, generalizations:,
                     packages:, stereotypes: [])
        @technology_name = technology_name
        @classifiers = classifiers.freeze
        @generalizations = generalizations.freeze
        @packages = packages.freeze
        @stereotypes = stereotypes.freeze
      end

      # O(1) classifier lookup by EA GUID. Returns ClassifierEntry
      # or nil.
      def find_by_guid(guid)
        classifier_guid_index[guid]
      end

      # O(1) classifier lookup by name. Returns the FIRST match —
      # MDGs typically use unique class names within a technology.
      def find_by_name(name)
        classifier_name_index[name]
      end

      # Returns the parent ClassifierEntry for a given child id,
      # or nil when the child has no MDG-defined parent.
      def parent_of(classifier_id)
        gen = generalizations.find { |g| g.specific_id == classifier_id }
        return nil unless gen

        find_by_guid(gen.general_id)
      end

      # Enumerates each classifier's ancestor chain (parent,
      # grandparent, ...). Stops at the root or when a cycle is
      # detected.
      def ancestors_of(classifier_id)
        seen = {}
        Enumerator.new do |yielder|
          current_id = classifier_id
          while current_id && !seen.key?(current_id)
            seen[current_id] = true
            parent = parent_of(current_id)
            break unless parent

            yielder << parent
            current_id = parent.id
          end
        end
      end

      # O(1) stereotype lookup by name. Returns StereotypeEntry or nil.
      def find_stereotype(name)
        stereotype_index[name]
      end

      private

      def classifier_guid_index
        @classifier_guid_index ||= classifiers.each_with_object({}) do |c, h|
          h[c.id] = c
        end
      end

      def classifier_name_index
        @classifier_name_index ||= classifiers.each_with_object({}) do |c, h|
          h[c.name] = c unless h.key?(c.name)
        end
      end

      def stereotype_index
        @stereotype_index ||= stereotypes.each_with_object({}) do |s, h|
          h[s.name] = s unless h.key?(s.name)
        end
      end
    end
  end
end
