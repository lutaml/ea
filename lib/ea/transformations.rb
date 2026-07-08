# frozen_string_literal: true

module Ea
  module Transformations
    autoload :Configuration, "ea/transformations/configuration"
    autoload :FormatRegistry, "ea/transformations/format_registry"
    autoload :TransformationEngine, "ea/transformations/transformation_engine"

    module Parsers
      autoload :BaseParser, "ea/transformations/parsers/base_parser"
      autoload :XmiParser, "ea/transformations/parsers/xmi_parser"
      autoload :QeaParser, "ea/transformations/parsers/qea_parser"
    end

    # Resolve a class name string to a constant
    # @param class_name [String] Fully qualified class name (e.g. "Ea::Foo::Bar")
    # @return [Class, nil] The resolved class constant, or nil if not found
    def self.constantize(class_name)
      parts = class_name.split("::")
      constant = Object
      parts.each { |part| constant = constant.const_get(part) }
      constant
    rescue NameError
      nil
    end

    class << self
      def engine
        @engine ||= TransformationEngine.new
      end

      def engine=(engine)
        @engine = engine
      end

      # Parse an EA file into its native representation.
      #
      # Pure entry point — does NOT require `lutaml-uml`. Returns:
      #   .qea → Ea::Qea::Database
      #   .xmi → Xmi::Sparx::Root
      #
      # To get a Lutaml::Uml::Document instead, use {to_uml}.
      #
      # @param file_path [String] path to a .qea or .xmi file
      # @param options [Hash] parser options (e.g. config: for QEA)
      # @return [Ea::Qea::Database, Xmi::Sparx::Root]
      def parse(file_path, options = {})
        ext = File.extname(file_path).downcase
        case ext
        when ".qea"
          Ea::Qea.load(file_path, options[:config])
        when ".xmi", ".xml"
          Ea::Xmi.load(file_path)
        else
          raise Ea::Error,
                "Unsupported file extension #{ext.inspect}. " \
                "Supported: .qea, .xmi"
        end
      end

      # Transform an EA file (or pre-parsed model) into a
      # `Lutaml::Uml::Document`.
      #
      # Bridge entry point — requires the optional `lutaml-uml` gem.
      # Lazy-loads the bridge code on first call.
      #
      # @param path_or_model [String, Ea::Qea::Database, Xmi::Sparx::Root]
      # @param options [Hash] transformation options
      # @return [Lutaml::Uml::Document]
      def to_uml(path_or_model, options = {})
        model = if path_or_model.is_a?(String)
                  parse(path_or_model, options)
                else
                  path_or_model
                end

        case model
        when Ea::Qea::Database
          Ea::Bridge::QeaToUml.transform(model, options)
        when ::Xmi::Sparx::Root
          Ea::Bridge::XmiToUml.transform(model)
        else
          raise Ea::Error,
                "Cannot transform #{model.class} to Lutaml::Uml::Document. " \
                "Expected Ea::Qea::Database or Xmi::Sparx::Root."
        end
      end

      def detect_parser(file_path)
        engine.detect_parser(file_path)
      end

      def supported_extensions
        engine.supported_extensions
      end

      def supports_file?(file_path)
        engine.supports_file?(file_path)
      end

      def statistics
        engine.statistics
      end

      def reset_statistics
        engine.clear_history
      end

      def validate_setup
        engine.validate_setup
      end

      def register_parser(extension, parser_class)
        engine.register_parser(extension, parser_class)
      end

      def load_configuration(config_path)
        engine.configuration = Configuration.load(config_path)
      end

      def configuration
        engine.configuration
      end

      def configuration=(config)
        engine.configuration = config
      end

      def configure
        yield(configuration) if block_given?
      end
    end
  end
end
