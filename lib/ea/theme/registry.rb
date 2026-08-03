# frozen_string_literal: true

module Ea
  module Theme
    # Central registry for theme Definitions. Lookup by ID returns
    # a fully configured Definition object. Adding a new theme =
    # registering it (OCP) — no existing code modified.
    #
    # Built-in themes are auto-loaded from `config/themes/*.yml` on
    # first access.
    #
    # Usage:
    #
    #   Ea::Theme::Registry.lookup(":119")  # → Definition
    #   Ea::Theme::Registry.register(my_def)
    #   Ea::Theme::Registry.all             # → [Definition, ...]
    #
    class Registry
      CONFIG_DIR = File.expand_path("../../../config/themes", __dir__)

      class << self
        # Returns all registered themes.
        # @return [Array<Ea::Theme::Definition>]
        def all
          themes.values
        end

        # Look up a theme by ID. Returns the default theme when
        # the ID is nil, empty, or unknown.
        #
        # EA stores theme IDs with a leading colon (":119"). The
        # lookup normalizes by stripping the colon.
        #
        # @param theme_id [String, Symbol, nil] theme identifier
        # @return [Ea::Theme::Definition]
        def lookup(theme_id)
          ensure_loaded
          return default if theme_id.nil? || theme_id.to_s.empty?

          key = normalize_key(theme_id)
          @themes[key] || default
        end

        # Register a new theme. Adding a theme does NOT modify
        # existing code (OCP).
        #
        # @param definition [Ea::Theme::Definition]
        def register(definition)
          ensure_loaded
          @themes[definition.id] = definition
        end

        # The default theme (no overrides, element-stored values).
        # @return [Ea::Theme::Definition]
        def default
          ensure_loaded
          @themes["default"]
        end

        # Load themes from a directory of YAML files. Each .yml
        # file produces one Definition.
        # @param dir [String] directory path
        def load_dir(dir)
          ensure_loaded
          Loader.load_dir(dir).each { |d| @themes[d.id] = d }
        end

        private

        def ensure_loaded
          return if @loaded

          @themes = {}
          @loaded = true
          load_builtin_themes
        end

        def load_builtin_themes
          return unless Dir.exist?(CONFIG_DIR)

          Loader.load_dir(CONFIG_DIR).each { |d| @themes[d.id] = d }
        end

        def normalize_key(theme_id)
          cleaned = theme_id.to_s.gsub(/^:/, "")
          cleaned.empty? ? "default" : cleaned
        end

        def themes
          ensure_loaded
          @themes
        end
      end
    end
  end
end
