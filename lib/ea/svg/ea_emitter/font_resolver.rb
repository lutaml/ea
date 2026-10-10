# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Resolves the effective font family + size for a DiagramElement,
      # using EA's fallback chain:
      #
      #   1. element.font_family / element.font_size (per-element override)
      #   2. theme.font_family / theme.font_size (when theme is themed)
      #   3. diagram-level default (most common non-nil value across
      #      the diagram's elements)
      #   4. locale fallback (Calibri 10)
      #
      # Lives outside the Elements emitter so the resolution rule is
      # defined once (MECE) and reusable by Labels and any future
      # text-emitting layer.
      class FontResolver
        DEFAULT_FONT_FAMILY = "Yu Gothic UI"
        # EA's default element compartment font size. EA-published
        # reference SVGs render body text at 7pt (the current EA
        # theme size) for every element whose objectstyle fontsz is
        # a use-default marker (see QEA DiagramBuilder.font_size_from).
        DEFAULT_ELEMENT_FONT_SIZE = 7

        attr_reader :diagram, :theme

        def initialize(diagram, theme: nil)
          @diagram = diagram
          @theme = theme || Ea::Theme::Registry.default
        end

        # Families EA stores as "use default" markers - the export
        # renders them with the theme font (corpus-wide, no published
        # SVG ever carries Yu Gothic UI).
        DEFAULT_MARKER_FAMILIES = ["Yu Gothic UI"].freeze

        def family_for(element)
          explicit = element&.font_family
          unless explicit.nil? || explicit.empty? ||
                 DEFAULT_MARKER_FAMILIES.include?(explicit)
            return explicit
          end
          return theme.font_family if theme.themed? && theme.font_family

          diagram_default_family || DEFAULT_FONT_FAMILY
        end

        def size_for(element)
          explicit = element&.font_size
          explicit = nil if explicit&.zero?
          return explicit if explicit

          # An element's own explicit fontsz never re-sizes its
          # neighbours: default elements always render at the theme
          # size (9BA1CE54: one 9pt label + six use-default
          # instances; EA publishes the six at 7pt).
          DEFAULT_ELEMENT_FONT_SIZE
        end

        def size_unit_for(_element)
          theme.font_size_unit || "pt"
        end

        def weight_for(element)
          bold = element&.font_bold ? 700 : nil
          bold || (theme.themed? ? theme.text_weight_normal : 400)
        end

        def style_for(element)
          element&.font_italic ? "italic" : "normal"
        end

        private

        # EA's app-default font depends on the system locale:
        # Japanese Windows → "Yu Gothic UI" 13, English Windows →
        # "Calibri" 10. We can't query EA's runtime, so we infer
        # from the diagram:
        #
        # - If ANY element specifies font=, use the most common.
        # - If NO element specifies font= (all are "use default"),
        #   assume the EA English-locale default: Calibri 10.
        def diagram_default_family
          families = element_families
          return FALLBACK_DEFAULT_FAMILY if families.empty?

          most_common(families)
        end

        FALLBACK_DEFAULT_FAMILY = "Calibri"

        def most_common(values)
          return nil if values.empty?

          tally = tally_values(values)
          tally.max_by { |_, count| count }.first
        end

        def element_families
          (diagram.elements || []).map(&:font_family).compact
        end

        def tally_values(values)
          values.each_with_object(Hash.new(0)) { |v, acc| acc[v] += 1 }
        end
      end
    end
  end
end
