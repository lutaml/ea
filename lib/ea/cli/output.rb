# frozen_string_literal: true

module Ea
  module Cli
    # Output formatters for the CLI. Each formatter self-registers via
    # `Ea::Cli::Output.register(:name, Class)` at file-load time. Lookup via
    # `Ea::Cli::Output.for(:name)` triggers autoloads on first access.
    module Output
      autoload :Formatter, "ea/cli/output/formatter"
      autoload :TableFormatter, "ea/cli/output/table_formatter"
      autoload :JsonFormatter, "ea/cli/output/json_formatter"
      autoload :YamlFormatter, "ea/cli/output/yaml_formatter"

      @formatters = {}
      @formatters_loaded = false

      class << self
        def register(name, klass)
          @formatters[name.to_sym] = klass
        end

        def for(name)
          ensure_formatters_loaded
          klass = @formatters[name.to_sym]
          klass ||
            raise(ArgumentError,
                  "No output formatter '#{name}'. " \
                  "Registered: #{@formatters.keys.join(', ')}")
        end

        # Convenience: returns a fresh formatter instance for `name`.
        def instance_for(name)
          self.for(name).new
        end

        def registered_formats
          ensure_formatters_loaded
          @formatters.keys
        end

        private

        # Trigger autoload of each known formatter so its self-register
        # block runs. Referencing the constant is enough.
        def ensure_formatters_loaded
          return if @formatters_loaded

          TableFormatter
          JsonFormatter
          YamlFormatter
          @formatters_loaded = true
        end
      end
    end
  end
end
