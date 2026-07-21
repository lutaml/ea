# frozen_string_literal: true

require "yaml"

module Ea
  module Svg
    # Resolves a classifier's stereotype to a fill color. Looks up
    # a YAML config (config/stereotype_colors.yml) by lowercase
    # stereotype name. Falls back to a default white when no match.
    #
    # Loading the YAML is memoized at the class level via a
    # class instance variable accessor method (no instance_variable_set).
    class StereotypeColorResolver
      DEFAULT_FILL = "#FFFFFF"
      DEFAULT_CONFIG_PATH = File.expand_path("../../../config/stereotype_colors.yml", __dir__)

      class << self
        # Memoize the loaded default map. Re-reading from disk is
        # expensive; load once per process.
        def default_map
          @default_map ||= load_yaml(DEFAULT_CONFIG_PATH)
        end

        # Test hook: clear the memo to force a reload.
        def reset_default_map
          @default_map = nil
        end

        def load_yaml(path)
          return {} unless File.exist?(path)

          YAML.safe_load(File.read(path)) || {}
        end
      end

      attr_reader :color_map, :default

      def initialize(color_map: self.class.default_map, default: DEFAULT_FILL)
        @color_map = color_map
        @default = default
      end

      def fill_for(stereotype_name)
        return default if stereotype_name.nil? || stereotype_name.empty?

        color_map[stereotype_name.downcase] || default
      end
    end
  end
end
