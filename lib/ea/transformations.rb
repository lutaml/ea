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

      def parse(file_path, options = {})
        engine.parse(file_path, options)
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
