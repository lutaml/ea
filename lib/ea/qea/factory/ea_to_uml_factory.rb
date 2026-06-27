# frozen_string_literal: true

module Ea
  module Qea
    module Factory
      # Main factory for orchestrating EA to UML transformation
      # Implements Facade pattern for complete model transformation
      class EaToUmlFactory
        attr_reader :database, :options, :resolver

        # Initialize factory with EA database
        # @param database [Ea::Qea::Database] Loaded EA database
        # @param options [Hash] Transformation options
        # @option options [Boolean] :include_diagrams Include diagrams
        # (default: true)
        # @option options [Boolean] :validate Validate output (default: true)
        # @option options [String] :document_name Document name
        def initialize(database, options = {})
          @database = database
          @options = default_options.merge(options)
          @resolver = ReferenceResolver.new
          @transformers = {}
        end

        # Create complete UML document from EA database
        # @return [Lutaml::Uml::Document] Complete UML document
        def create_document # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          builder = DocumentBuilder.new(
            name: options[:document_name] || "EA Model",
          )

          # Transform packages with hierarchy (includes all classes)
          packages = transform_packages

          # Transform associations (references classes by xmi_id)
          associations = transform_associations

          # Collect class-level associations from packages
          # class-level associations contain associations with both directions
          # and it may include associations in connector level
          # i.e. owner_end -> member_end and member_end -> owner_end
          class_associations = collect_class_association(packages)

          # Orphaned classes: EA class objects whose package_id does not
          # resolve to a known package. Attach them to the document root so
          # their associations can resolve.
          orphan_classes = transform_orphan_classes

          # Build document with both connector-level and
          # class-level associations
          builder.add_packages(packages)
            .add_classes(orphan_classes)
            .add_associations(associations)
            .add_associations(class_associations)

          # Add diagrams if requested
          if options[:include_diagrams]
            builder.add_diagrams(transform_diagrams)
          end

          builder.build(validate: options[:validate])
        end

        # Transform all packages with hierarchy
        # @return [Array<Lutaml::Uml::Package>] Root packages
        def transform_packages # rubocop:disable Metrics/MethodLength
          root_packages = database.packages.select do |pkg|
            pkg.parent_id.nil? || pkg.parent_id.zero?
          end

          package_transformer = get_transformer(:package)
          root_packages.filter_map do |ea_package|
            uml_package = package_transformer.transform_with_hierarchy(
              ea_package,
              include_children: true,
            )

            register_package_hierarchy(uml_package)

            uml_package
          end
        end

        # Transform EA class objects that have no resolvable parent package.
        #
        # EA occasionally stores class rows whose `package_id` does not
        # correspond to any row in `t_package` (typically the result of a
        # deleted package whose children were not reparented). These classes
        # would otherwise be silently dropped, breaking any associations that
        # reference them. Attach them to the document root instead.
        #
        # @return [Array<Lutaml::Uml::UmlClass>] Orphaned UML classes
        def transform_orphan_classes
          class_transformer = get_transformer(:class)

          orphans = ea_class_objects.reject do |ea_object|
            package_known?(ea_object.package_id)
          end

          uml_classes = class_transformer.transform_collection(orphans)
          uml_classes.each { |uml_class| register_element(uml_class) }
          uml_classes
        end

        # All EA class-like objects (classes and interfaces)
        # @return [Array<Ea::Qea::Models::EaObject>]
        def ea_class_objects
          database.objects.find_by_type("Class") +
            database.objects.find_by_type("Interface")
        end

        # Whether a package_id resolves to a known package in t_package
        # @param package_id [Integer, nil]
        # @return [Boolean]
        def package_known?(package_id)
          return false if package_id.nil?

          !database.find_package(package_id).nil?
        end

        # Transform all associations
        # @return [Array<Lutaml::Uml::Association>] All UML associations
        def transform_associations # rubocop:disable Metrics/MethodLength
          association_transformer = get_transformer(:association)

          ea_associations = database.connectors.select(&:association?)

          uml_associations = association_transformer.transform_collection(
            ea_associations,
          )

          uml_associations.each do |uml_assoc|
            register_element(uml_assoc)
          end

          uml_associations
        end

        # Transform all diagrams
        # @return [Array<Lutaml::Uml::Diagram>] All UML diagrams
        def transform_diagrams
          diagram_transformer = get_transformer(:diagram)
          diagram_transformer.transform_collection(database.diagrams)
        end

        # Register custom transformers, overriding registry defaults
        # @param transformers [Hash] Custom transformer instances keyed by type
        # @return [self] For method chaining
        def with_transformers(transformers)
          @transformers.merge!(transformers)
          self
        end

        private

        def default_options
          {
            include_diagrams: true,
            validate: true,
            document_name: "EA Model",
          }
        end

        # Get or create transformer by type using the TransformerRegistry
        # @param type [Symbol] Transformer type
        # @return [BaseTransformer] Transformer instance
        def get_transformer(type)
          return @transformers[type] if @transformers.key?(type)

          transformer_class = TransformerRegistry.transformer_for(type)
          unless transformer_class
            raise ArgumentError, "Unknown transformer type: #{type}"
          end

          @transformers[type] = transformer_class.new(database)
        end

        def register_package_hierarchy(package)
          return if package.nil?

          register_element(package)
          register_package_members(package)

          package.packages&.each do |child_package|
            register_package_hierarchy(child_package)
          end
        end

        MEMBER_COLLECTIONS = %i[classes enums data_types instances].freeze

        def register_package_members(package)
          MEMBER_COLLECTIONS.each do |collection|
            package.public_send(collection)&.each do |elem|
              register_element(elem)
            end
          end
        end

        def register_element(element)
          return if element.nil? || element.xmi_id.nil?

          @resolver.register(element.xmi_id, element)
        end

        def collect_class_association(packages)
          associations = []

          packages.each do |package|
            collect_package_associations(package, associations)
          end

          associations
        end

        def collect_package_associations(package, associations) # rubocop:disable Metrics/CyclomaticComplexity
          package.classes&.each do |klass|
            if klass.associations && !klass.associations.empty?
              associations.concat(klass.associations)
            end
          end

          package.packages&.each do |child_package|
            collect_package_associations(child_package, associations)
          end
        end
      end
    end
  end
end
