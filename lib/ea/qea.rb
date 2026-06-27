# frozen_string_literal: true

module Ea
  module Qea
    autoload :Infrastructure, "ea/qea/infrastructure"
    autoload :Services, "ea/qea/services"
    autoload :Models, "ea/qea/models"
    autoload :Factory, "ea/qea/factory"
    autoload :Validation, "ea/qea/validation"
    autoload :Verification, "ea/qea/verification"
    autoload :Database, "ea/qea/database"
    autoload :Repositories, "ea/qea/repositories"
    autoload :Benchmark, "ea/qea/benchmark"
    autoload :FileDetector, "ea/qea/file_detector"

    class << self
      # Get the current configuration
      #
      # @return [Services::Configuration] The loaded configuration
      def configuration
        @configuration ||= Services::Configuration.load
      end

      # Set a custom configuration
      #
      # @param config [Services::Configuration] The configuration to use
      def configuration=(config)
        @configuration = config
      end

      # Reload configuration from file
      #
      # @param config_path [String, nil] Optional custom config path
      # @return [Services::Configuration] The reloaded configuration
      def reload_configuration(config_path = nil)
        @configuration = Services::Configuration.load(config_path)
      end

      # Connect to a QEA file
      #
      # @param file_path [String] Path to the .qea file
      # @return [Infrastructure::DatabaseConnection] The connection object
      def connect(file_path)
        Infrastructure::DatabaseConnection.new(file_path)
      end

      # Open a QEA file and yield the connection
      #
      # @param file_path [String] Path to the .qea file
      # @yield [Infrastructure::DatabaseConnection] The connection object
      # @return [Object] The result of the block
      def open(file_path)
        connection = connect(file_path)
        yield connection
      ensure
        connection&.close if connection&.connected?
      end

      # Get schema information from a QEA file
      #
      # @param file_path [String] Path to the .qea file
      # @return [Hash] Schema information including tables and row counts
      def schema_info(file_path)
        connection = connect(file_path)
        connection.with_connection do |db|
          reader = Infrastructure::SchemaReader.new(db)
          {
            tables: reader.tables,
            statistics: reader.statistics,
          }
        end
      ensure
        connection&.close if connection&.connected?
      end

      # Load complete database with all tables and models (standalone API)
      #
      # This is the primary standalone entry point — returns EA-native data
      # without requiring lutaml-uml.
      #
      # @param qea_path [String] Path to the .qea file
      # @param config [Services::Configuration, nil] Optional custom config
      # @return [Database] Loaded database with all collections
      def load(qea_path, config = nil, &progress_callback)
        load_database(qea_path, config, &progress_callback)
      end

      # Load complete database with all tables and models
      #
      # @param qea_path [String] Path to the .qea file
      # @param config [Services::Configuration, nil]
      # @return [Database] Loaded database with all collections
      def load_database(qea_path, config = nil, &progress_callback)
        loader = Services::DatabaseLoader.new(qea_path, config)
        loader.on_progress(&progress_callback) if progress_callback
        loader.load
      end

      # Get quick database statistics without full loading
      #
      # @param qea_path [String] Path to the .qea file
      # @param config [Services::Configuration, nil]
      # @return [Hash<String, Integer>] Collection names to record counts
      def database_info(qea_path, config = nil)
        loader = Services::DatabaseLoader.new(qea_path, config)
        loader.quick_stats
      end

      # Convert an EA database to a UML Document (requires lutaml-uml)
      #
      # @param database [Database] Loaded EA database
      # @param options [Hash] Transformation options
      # @return [Lutaml::Uml::Document] UML document
      # @raise [Ea::Error] if lutaml-uml is not available
      def to_uml(database, options = {})
        require_uml!
        factory = Factory::EaToUmlFactory.new(database, options)
        factory.create_document
      end

      # Parse QEA file to UML Document (convenience: load + to_uml)
      #
      # Requires lutaml-uml for the UML conversion.
      #
      # @param qea_path [String] Path to the .qea file
      # @param options [Hash] Transformation options
      # @return [Lutaml::Uml::Document, Hash] Document, or hash with
      #   :document and :validation_result
      # @raise [Ea::Error] if lutaml-uml is not available
      def parse(qea_path, options = {}) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        require_uml!
        config = options.delete(:config)
        validate = options.delete(:validate)

        loader = Services::DatabaseLoader.new(qea_path, config)
        ea_database = loader.load

        begin
          factory = Factory::EaToUmlFactory.new(ea_database, options)
          document = factory.create_document

          if validate
            engine = Validation::ValidationEngine.new(
              document,
              database: ea_database,
              **options,
            )
            validation_result = engine.validate

            {
              document: document,
              validation_result: validation_result,
            }
          else
            document
          end
        ensure
          ea_database.close_connection unless validate
        end
      end

      private

      # Ensure lutaml-uml is available for UML conversion operations
      #
      # @raise [Ea::Error] if lutaml-uml is not loaded
      def require_uml!
        return if defined?(Lutaml::Uml::Document)

        begin
          require "lutaml/uml"
        rescue LoadError
          raise Ea::Error,
                "lutaml-uml is required for UML conversion. " \
                "Add gem 'lutaml-uml' to your Gemfile."
        end

        return if defined?(Lutaml::Uml::Document)

        raise Ea::Error,
              "lutaml-uml failed to load Lutaml::Uml::Document."
      end
    end
  end
end
