# frozen_string_literal: true

module Ea
  module Model
    # A diagram: an ordered set of placed elements and connectors.
    # The diagram references the package it belongs to (by id) and
    # owns its elements/connectors compositionally.
    class Diagram < Base
      attribute :package_id, :string
      attribute :diagram_type, :string  # logical|class|sequence|use_case|...
      attribute :bounds, Bounds         # canvas size
      attribute :style, :string         # raw t_diagram.Style (HideAtts=1;HideOps=0;...)
      attribute :style_ex, :string      # raw t_diagram.StyleEx (Theme=:NNN;SuppressFOC=1;...)
      attribute :theme_override_id, :string # set by theme= when given an ID
      attribute :show_package_contents, :boolean, default: false
      attribute :hand_draw, :boolean, default: false
      attribute :show_notes, :boolean, default: false
      attribute :show_parents, :boolean, default: true
      attribute :elements, DiagramElement, collection: true, initialize_empty: true
      attribute :connectors, DiagramConnector, collection: true, initialize_empty: true
      attribute :annotations, Annotation, collection: true, initialize_empty: true

      json do
        map "id", to: :id
        map "name", to: :name
        map "packageId", to: :package_id
        map "diagramType", to: :diagram_type
        map "bounds", to: :bounds
        map "style", to: :style
        map "styleEx", to: :style_ex
        map "themeOverrideId", to: :theme_override_id
        map "showPackageContents", to: :show_package_contents
        map "handDraw", to: :hand_draw
        map "showNotes", to: :show_notes
        map "showParents", to: :show_parents
        map "elements", to: :elements, render_empty: true
        map "connectors", to: :connectors, render_empty: true
        map "annotations", to: :annotations, render_empty: true
      end

      # Parses style_ex into a Hash of flag => value. Returns empty
      # Hash when style_ex is nil/empty.
      #
      # Example: "Theme=:119;SuppressFOC=1;AttPkg=1" →
      #   { "Theme" => ":119", "SuppressFOC" => "1", "AttPkg" => "1" }
      def style_ex_flags
        return {} if style_ex.nil? || style_ex.empty?

        style_ex.split(";").filter_map do |pair|
          next nil unless pair.include?("=")

          key, value = pair.split("=", 2)
          [key, value.to_s] if key && !key.empty?
        end.to_h
      end

      # Returns the effective theme ID. Resolved from (in order):
      #   1. theme_override_id (set by theme=)
      #   2. style_ex_flags["Theme"]
      #
      # @return [String, nil]
      def theme_id
        theme_override_id || style_ex_flags["Theme"]
      end

      # Returns the resolved Theme Definition. Looks up from the
      # Registry by theme_id, falling back to default.
      #
      # @return [Ea::Theme::Definition]
      def theme
        Ea::Theme::Registry.lookup(theme_id)
      end

      # Returns the DisplayConfig parsed from style + style_ex.
      # Controls behavioral rendering flags (HideAtts, HideOps,
      # SuppressFOC, AttPub, ShowNotes, etc.).
      #
      # @return [Ea::Diagram::DisplayConfig]
      def display_config
        Ea::Diagram::DisplayConfig.from_style(style:, style_ex:)
      end

      # Set the diagram's theme. Accepts:
      #
      #   diagram.theme = :119          # by Symbol ID
      #   diagram.theme = ":119"        # by String ID
      #   diagram.theme = "119"         # by String ID (no colon)
      #   diagram.theme = definition    # by Definition object
      #
      # When given an ID, sets theme_override_id. When given a
      # Definition, registers it in the Registry and stores its ID.
      #
      # @param value [Symbol, String, Ea::Theme::Definition]
      def theme=(value)
        case value
        when Ea::Theme::Definition
          Ea::Theme::Registry.register(value)
          @theme_override_id = value.id
        else
          @theme_override_id = normalize_theme_id(value)
        end
      end

      private

      def normalize_theme_id(value)
        return nil if value.nil?

        value.to_s.gsub(/^:/, "")
      end
    end
  end
end
