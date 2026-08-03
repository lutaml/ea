# frozen_string_literal: true

module Ea
  module Diagram
    # Models the behavioral display flags from t_diagram.Style and
    # t_diagram.StyleEx. Controls WHAT is rendered (compartments,
    # visibility levels, notes) — distinct from Theme which controls
    # HOW it looks (colors, fonts, stroke widths).
    #
    # Style (a.k.a. Style1) carries the per-diagram visibility
    # toggles set via the "Features" panel:
    #
    #   HideAtts=1   → hide attribute compartment
    #   HideOps=1    → hide operation compartment
    #   HideStereo=1 → hide stereotype labels
    #
    # StyleEx carries extended flags including the theme identifier
    # and notes/labels visibility:
    #
    #   Theme=:119    → theme id (consumed by Ea::Theme::Registry)
    #   SuppressFOC=1 → suppress foreign object content (images, OLE)
    #   AttPub=1      → show public attributes
    #   AttPri=1      → show private attributes
    #   AttPro=1      → show protected attributes
    #   ShowNotes=0   → hide element notes
    #   ShowBorder=1  → render diagram frame
    #   HideQuals=0   → show qualifier names
    #   SuppConnLbls=0 → show connector labels
    #
    # Usage:
    #   config = DisplayConfig.from_style(style: diagram.style,
    #                                      style_ex: diagram.style_ex)
    #   config.show_attributes?  # → false iff Style has HideAtts=1
    #
    class DisplayConfig
      DEFAULT_SHOW_PUBLIC = "1"
      DEFAULT_SHOW_PRIVATE = "1"
      DEFAULT_SHOW_PROTECTED = "1"
      DEFAULT_SHOW_BORDER = "1"
      DEFAULT_SUPPRESS_CONN_LABELS = "0"
      DEFAULT_SHOW_NOTES = "0"

      attr_reader :style_flags, :style_ex_flags

      def initialize(style_flags: {}, style_ex_flags: {})
        @style_flags = style_flags
        @style_ex_flags = style_ex_flags
      end

      # Build a DisplayConfig from the raw Style and StyleEx strings.
      # Both are optional; missing strings produce an empty flag set.
      #
      # @param style [String, nil] t_diagram.Style content
      # @param style_ex [String, nil] t_diagram.StyleEx content
      # @return [DisplayConfig]
      def self.from_style(style:, style_ex:)
        new(style_flags: parse_flags(style),
            style_ex_flags: parse_flags(style_ex))
      end

      # Backwards-compatible single-arg form: treats the argument as
      # StyleEx. New callers should pass both style: and style_ex:.
      def self.from_style_ex(style_ex)
        from_style(style: nil, style_ex: style_ex)
      end

      # ---- Feature visibility (Style) ----

      def show_attributes?
        style_flags["HideAtts"] != "1"
      end

      def show_operations?
        style_flags["HideOps"] != "1"
      end

      def show_stereotypes?
        style_flags["HideStereo"] != "1"
      end

      # Tagged values compartment. EA defaults to hiding it; the user
      # explicitly opts in via Style1 ShowTags=1.
      def show_tagged_values?
        style_flags["ShowTags"] == "1"
      end

      # Extended stereotype labels (e.g., profile-specific stereotypes
      # beyond UML's standard set). EA defaults to showing them.
      def show_extended_stereotypes?
        style_flags["HideEStereo"] != "1"
      end

      # Sequence numbers on elements. EA defaults to hiding them.
      def show_sequence_numbers?
        style_flags["ShowSN"] == "1"
      end

      # Operation parameter type list. When false, EA shows `op()`
      # instead of `op(name: Type)`. Defaults to true.
      def show_operation_parameters?
        style_flags["OpParams"] != "0"
      end

      # Element Alias instead of Name in the header. Defaults to false
      # — most diagrams show the Name.
      def use_alias?
        style_flags["UseAlias"] == "1"
      end

      # Connector role/name labels. EA defaults to showing them.
      def show_connector_names?
        style_flags["SuppCN"] != "1"
      end

      # Constraints compartment (OCL invariants). Defaults to false.
      def show_constraints?
        style_flags["ShowCons"] == "1"
      end

      # Page indicator scaling (Print... → Show Page Breaks).
      def scale_page_indicators?
        style_flags["ScalePI"] == "1"
      end

      # ---- Attribute visibility levels (StyleEx) ----

      def show_public_attributes?
        style_ex_flags.fetch("AttPub", DEFAULT_SHOW_PUBLIC) == "1"
      end

      def show_private_attributes?
        style_ex_flags.fetch("AttPri", DEFAULT_SHOW_PRIVATE) == "1"
      end

      def show_protected_attributes?
        style_ex_flags.fetch("AttPro", DEFAULT_SHOW_PROTECTED) == "1"
      end

      # ---- Diagram decorations (StyleEx) ----

      def show_notes?
        style_ex_flags.fetch("ShowNotes", DEFAULT_SHOW_NOTES) == "1"
      end

      def show_border?
        style_ex_flags.fetch("ShowBorder", DEFAULT_SHOW_BORDER) == "1"
      end

      def show_connector_labels?
        style_ex_flags.fetch("SuppConnectorLabels",
                              DEFAULT_SUPPRESS_CONN_LABELS) != "1"
      end

      def hide_qualifiers?
        style_ex_flags["HideQuals"] == "1"
      end

      def suppress_foreign_object_content?
        style_ex_flags["SuppressFOC"] == "1"
      end

      # Serialize the union of flags back to a StyleEx-shaped string.
      # Style and StyleEx are merged because EA serializes them as
      # one string when round-tripped through some tools.
      def to_style_ex
        style_flags.merge(style_ex_flags).map { |k, v| "#{k}=#{v}" }.join(";")
      end

      # ---- private ----

      def self.parse_flags(raw)
        return {} if raw.nil? || raw.empty?

        raw.split(";").filter_map do |pair|
          next nil unless pair.include?("=")

          key, value = pair.split("=", 2)
          [key, value.to_s] if key && !key.empty?
        end.to_h
      end
      private_class_method :parse_flags
    end
  end
end
