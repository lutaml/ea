# frozen_string_literal: true

module Ea
  module Cli
    class Error < Ea::Error; end

    class FileNotFound < Error
      def initialize(path)
        super("File not found: #{path}")
      end
    end

    class UnsupportedFormat < Error
      def initialize(path, detail = nil)
        msg = "Unsupported format for file: #{path}"
        msg = "#{msg} (#{detail})" if detail
        super(msg)
      end
    end

    class MissingUmlDependency < Error
      def initialize
        super("lutaml-uml is required for this command. " \
              "Add gem 'lutaml-uml' to your Gemfile.")
      end
    end

    class UnknownAction < Error
      def initialize(action, valid:)
        super("Unknown action '#{action}'. Valid: #{valid.join(', ')}")
      end
    end
  end
end
