# frozen_string_literal: true

module Ea
  module Qea
    module Factory
      # Transforms EA packages to UML packages
      class PackageTransformer < BaseTransformer
        # Transform EA package to UML package
        # @param ea_package [EaPackage] EA package model
        # @return [Lutaml::Uml::Package] UML package
        def transform(ea_package) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          return nil if ea_package.nil?

          Lutaml::Uml::Package.new.tap do |pkg|
            # Map basic properties
            pkg.name = ea_package.name
            pkg.xmi_id = normalize_guid_to_xmi_format(ea_package.ea_guid,
                                                      "EAPK")

            # Map definition/notes
            pkg.definition = ea_package.notes unless
              ea_package.notes.nil? || ea_package.notes.empty?

            # Load and transform tagged values
            pkg.tagged_values = load_tagged_values(ea_package.ea_guid)

            # Load stereotype from t_xref
            stereotype = load_stereotype(ea_package.ea_guid)
            pkg.stereotype = [stereotype] if stereotype

            # Note: Child packages and contents will be loaded separately
            # to avoid circular dependencies and allow lazy loading
            # Don't initialize collections - they have default values
          end
        end

        # Transform and build complete package hierarchy
        # @param ea_package [EaPackage] Root EA package
        # @param include_children [Boolean] Whether to recursively load children
        # @return [Lutaml::Uml::Package] Complete UML package with hierarchy
        def transform_with_hierarchy(ea_package, include_children: true)
          pkg = transform(ea_package)
          return pkg unless include_children

          # Load child packages
          child_packages = load_child_packages(ea_package.package_id)
          pkg.packages = child_packages.map do |child_pkg|
            transform_with_hierarchy(child_pkg, include_children: true)
          end

          # Load package contents (classes, diagrams, etc.)
          load_package_contents(pkg, ea_package.package_id)

          pkg
        end

        private

        # Load child packages
        # @param parent_id [Integer] Parent package ID
        # @return [Array<EaPackage>] Child packages
        def load_child_packages(parent_id)
          return [] if parent_id.nil?

          database.child_packages_for(parent_id)
            .sort_by { |p| p.tpos || 0 }
        end

        # Load package contents (objects and diagrams)
        # @param pkg [Lutaml::Uml::Package] UML package to populate
        # @param package_id [Integer] EA package ID
        def load_package_contents(pkg, package_id)
          return if package_id.nil?

          # Load objects (classes, etc.) in this package
          load_package_objects(pkg, package_id)

          # Load diagrams in this package
          load_package_diagrams(pkg, package_id)
        end

        # Maps transformer type keys to UML Package collection methods
        COLLECTION_FOR_TYPE = {
          class: :classes,
          enumeration: :enums,
          data_type: :data_types,
          instance: :instances,
        }.freeze

        # Load objects for a package
        # @param pkg [Lutaml::Uml::Package] UML package
        # @param package_id [Integer] Package ID
        def load_package_objects(pkg, package_id)
          ea_objects = database.objects_in_package(package_id)

          ea_objects.each do |ea_obj|
            type_key = ea_obj.transformer_type
            next unless type_key && COLLECTION_FOR_TYPE.key?(type_key)

            transformer_class = TransformerRegistry.transformer_for(type_key)
            next unless transformer_class

            uml_element = transformer_class.new(database).transform(ea_obj)
            next unless uml_element

            collection = COLLECTION_FOR_TYPE[type_key]
            pkg.public_send(collection) << uml_element
          end
        end

        # Load diagrams for a package
        # @param pkg [Lutaml::Uml::Package] UML package
        # @param package_id [Integer] Package ID
        def load_package_diagrams(pkg, package_id)
          diagram_transformer = DiagramTransformer.new(database)

          ea_diagrams = database.diagrams_in_package(package_id)
          pkg.diagrams = diagram_transformer.transform_collection(ea_diagrams)
        end

        # Load stereotype from t_xref table
        # @param ea_guid [String] Element GUID
        # @return [String, nil] Stereotype value (as string to match XMI format)
        def load_stereotype(ea_guid)
          return nil if ea_guid.nil?

          StereotypeLoader.new(database).load_from_xref(ea_guid)
        end

        # Check if an object appears on any diagram
        # @param object_id [Integer] Object ID
        # @return [Boolean] True if object appears on a diagram
        def appears_on_diagram?(object_id)
          return false if object_id.nil?
          return false unless database.diagram_objects

          # Check if object appears in any diagram's objects
          database.diagram_objects.any? do |dobj|
            dobj.ea_object_id == object_id
          end
        end
      end
    end
  end
end
