# frozen_string_literal: true

module Ea
  module Qea
    module Validation
      # Main orchestrator for the validation system
      # Coordinates all validators and consolidates results
      #
      # @example Basic usage
      #   engine = ValidationEngine.new(document, database: db)
      #   result = engine.validate
      #   puts result.summary
      #
      # @example With specific validators
      #   engine = ValidationEngine.new(document, database: db)
      #   result = engine.validate(validators: [:package, :class])
      class ValidationEngine
        attr_reader :document, :database, :registry, :options

        # Creates a new validation engine
        #
        # @param document [Object] The document to validate
        # @param database [Ea::Qea::Database] Database connection
        # @param options [Hash] Validation options
        # @option options [Boolean] :strict Fail on errors
        # @option options [Boolean] :verbose Detailed output
        # @option options [Symbol] :min_severity Minimum severity to report
        # @option options [Array<Symbol>] :categories Categories to check
        def initialize(document, database: nil, **options)
          @document = document
          @database = database
          @options = options
          @registry = ValidatorRegistry.new
          setup_default_validators
        end

        # Runs validation using two-phase architecture
        #
        # Phase 1: QEA Database Integrity Validation
        # - Validates EA database schema constraints
        # - Checks referential integrity
        # - Detects orphaned records
        # - Finds circular references
        #
        # Phase 2: UML Tree Structure Validation
        # - Validates transformed UML document tree
        # - Checks proper nesting
        # - Validates duplicate names
        # - Verifies type references
        #
        # @param validators [Array<Symbol>, nil] List of validators to run,
        #   or nil to run all
        # @return [ValidationResult]
        def validate(validators: nil) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          result = ValidationResult.new
          context = build_context
          context[:result] = result

          # Phase 1: QEA Database Validation
          phase1_result = validate_qea_database(context, validators)

          # Phase 2: UML Tree Validation
          phase2_result = validate_uml_tree(context, validators)

          # Merge results
          phase1_result.messages.each { |msg| result.messages << msg }
          phase2_result.messages.each { |msg| result.messages << msg }

          filter_result(result)
        end

        # Validates QEA database integrity
        #
        # @param context [Hash] Validation context
        # @param validators [Array<Symbol>, nil] Optional validator filter
        # @return [ValidationResult]
        def validate_qea_database(context, validators = nil) # rubocop:disable Metrics/MethodLength
          result = ValidationResult.new
          db_context = context.merge(result: result)

          database_validators = %i[
            referential_integrity
            orphan
            circular_reference
            package
          ]

          validator_names = if validators
                              (database_validators & validators)
                            else
                              database_validators
                            end

          validator_names.each do |name|
            next unless @registry.registered?(name)

            @registry.validate(name, db_context)
          end

          result
        end

        # Validates UML document tree structure
        #
        # @param context [Hash] Validation context
        # @param validators [Array<Symbol>, nil] Optional validator filter
        # @return [ValidationResult]
        def validate_uml_tree(context, validators = nil) # rubocop:disable Metrics/MethodLength
          result = ValidationResult.new
          uml_context = context.merge(result: result)

          uml_validators = %i[
            document_structure
            class
            attribute
            operation
            association
            diagram
          ]

          validator_names = if validators
                              (uml_validators & validators)
                            else
                              uml_validators
                            end

          validator_names.each do |name|
            next unless @registry.registered?(name)

            @registry.validate(name, uml_context)
          end

          result
        end

        # Validates and displays the result
        #
        # @param validators [Array<Symbol>, nil] List of validators to run
        # @param formatter [Symbol] Output format (:text, :json, :html)
        # @return [ValidationResult]
        def validate_and_display(validators: nil, formatter: :text)
          result = validate(validators: validators)
          display_result(result, formatter)
          result
        end

        # Registers a custom validator
        #
        # @param name [Symbol] Validator name
        # @param validator_class [Class] Validator class
        # @return [void]
        def register_validator(name, validator_class)
          @registry.register(name, validator_class)
        end

        # Checks if validation passed (no errors)
        #
        # @param validators [Array<Symbol>, nil] List of validators to run
        # @return [Boolean]
        def valid?(validators: nil)
          result = validate(validators: validators)
          !result.has_errors?
        end

        # Builds validation context from document and database
        #
        # @return [Hash]
        def build_context
          @context_cache ||= build_context_internal
        end

        private

        def build_context_internal # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
          context = {
            document: @document,
            database: @database,
            options: @options,
          }

          # Extract entities from transformed document (preferred source)
          if @document
            context[:classes] = extract_all_from_document(@document, :classes)
            context[:packages] = extract_all_packages(@document)
            context[:enumerations] = extract_all_from_document(@document, :enums)
            context[:data_types] = extract_all_from_document(@document, :data_types)
            context[:associations] = @document.associations || []
          end

          # Add database entities for referential integrity checks only
          # Note: Use document entities for primary validation
          if @database
            context[:db_packages] = @database.packages || []
            context[:db_objects] = @database.objects.all
            context[:attributes] = @database.attributes || []
            context[:operations] = @database.operations || []
            context[:connectors] = @database.connectors || []
            context[:diagrams] = @database.diagrams || []
            context[:diagram_objects] = @database.diagram_objects || []
            context[:diagram_links] = @database.diagram_links || []
          end

          context
        end

        #
        # @return [void]
        def setup_default_validators # rubocop:disable Metrics/MethodLength
          # Phase 1: QEA Database Integrity Validators
          @registry.register(:referential_integrity,
                             ReferentialIntegrityValidator)
          @registry.register(:orphan, OrphanValidator)
          @registry.register(:circular_reference,
                             CircularReferenceValidator)
          @registry.register(:package, PackageValidator)

          # Phase 2: UML Tree Structure Validators
          # DocumentStructureValidator lives in lutaml-uml and may not be
          # available (or may reference a different BaseValidator namespace).
          # Register it only if it can be loaded.
          begin
            @registry.register(:document_structure,
                               Lutaml::Uml::Validation::DocumentStructureValidator)
          rescue NameError
            # lutaml-uml's DocumentStructureValidator not available — skip
          end
          @registry.register(:class, ClassValidator)
          @registry.register(:attribute, AttributeValidator)
          @registry.register(:operation, OperationValidator)
          @registry.register(:association, AssociationValidator)
          @registry.register(:diagram, DiagramValidator)
        end

        # Extract all elements of a given type from document hierarchy
        # @param document [Lutaml::Uml::Document]
        # @param collection_method [Symbol] Method name on Package/Document
        # @return [Array<Object>]
        def extract_all_from_document(document, collection_method)
          items = (document.public_send(collection_method) || []).dup
          (document.packages || []).each do |package|
            concat_from_package_tree(items, package, collection_method)
          end
          items
        end

        # Recursively collect items from package tree
        # @param items [Array] Accumulator
        # @param package [Lutaml::Uml::Package]
        # @param collection_method [Symbol] Method name on Package
        def concat_from_package_tree(items, package, collection_method)
          items.concat(package.public_send(collection_method) || [])
          (package.packages || []).each do |child|
            concat_from_package_tree(items, child, collection_method)
          end
        end

        # Extract all packages from document hierarchy (includes packages
        # themselves, not just their contents)
        # @param document [Lutaml::Uml::Document]
        # @return [Array<Lutaml::Uml::Package>]
        def extract_all_packages(document)
          packages = []
          (document.packages || []).each { |pkg| collect_packages(packages, pkg) }
          packages
        end

        def collect_packages(result, package)
          result << package
          (package.packages || []).each { |child| collect_packages(result, child) }
        end

        # Filters result based on options
        #
        # @param result [ValidationResult]
        # @return [ValidationResult]
        def filter_result(result)
          return result unless @options[:min_severity] ||
            @options[:categories]

          filtered_result = ValidationResult.new

          result.messages.each do |message|
            next if severity_filtered?(message)
            next if category_filtered?(message)

            filtered_result.messages << message
          end

          filtered_result
        end

        # Checks if message should be filtered by severity
        #
        # @param message [ValidationMessage]
        # @return [Boolean]
        def severity_filtered?(message)
          return false unless @options[:min_severity]

          severity_levels = {
            info: 0,
            warning: 1,
            error: 2,
          }

          min_level = severity_levels[@options[:min_severity]] || 0
          message_level = severity_levels[message.severity] || 0

          message_level < min_level
        end

        # Checks if message should be filtered by category
        #
        # @param message [ValidationMessage]
        # @return [Boolean]
        def category_filtered?(message)
          return false unless @options[:categories]

          !@options[:categories].include?(message.category)
        end

        # Displays validation result
        #
        # @param result [ValidationResult]
        # @param formatter [Symbol] Output format
        # @return [void]
        def display_result(result, formatter)
          case formatter
          when :json
            puts result.to_json
          else
            display_text_result(result)
          end
        end

        # Displays result in text format
        #
        # @param result [ValidationResult]
        # @return [void]
        def display_text_result(result) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          puts "=" * 80
          puts "VALIDATION REPORT"
          puts "=" * 80
          puts
          puts result.summary
          puts

          if result.has_errors?
            puts "ERRORS (#{result.errors.size}):"
            puts
            display_messages_by_category(result.errors)
          end

          if result.has_warnings?
            puts
            puts "WARNINGS (#{result.warnings.size}):"
            puts
            display_messages_by_category(result.warnings)
          end

          if result.has_info? && @options[:verbose]
            puts
            puts "INFO (#{result.info.size}):"
            puts
            display_messages_by_category(result.info)
          end

          puts "=" * 80
        end

        # Displays messages grouped by category
        #
        # @param messages [Array<ValidationMessage>]
        # @return [void]
        def display_messages_by_category(messages)
          messages.group_by(&:category).each do |category, msgs|
            puts "  #{category.to_s.split('_').map(&:capitalize).join(' ')} " \
                 "(#{msgs.size}):"
            msgs.each do |msg|
              puts "    #{msg}"
              puts
            end
          end
        end
      end
    end
  end
end
