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
      #   4. unthemed fallback (Cambria)
      #
      # Lives outside the Elements emitter so the resolution rule is
      # defined once (MECE) and reusable by Labels and any future
      # text-emitting layer.
      class FontResolver
        DEFAULT_FONT_FAMILY = "Yu Gothic UI"
        # EA draws every text kind of a hand-drawn diagram (names, notes,
        # connector labels) in this family.
        HAND_DRAW_FAMILY = "Source Sans Pro"
        # Native hand-drawn connector end labels carry font-weight:0.
        HAND_DRAW_LABEL_WEIGHT = 0
        # EA's default element compartment font size. EA-published
        # reference SVGs render body text at 7pt (the current EA
        # theme size) for every element whose objectstyle fontsz is
        # a use-default marker (see QEA DiagramBuilder.font_size_from).
        DEFAULT_ELEMENT_FONT_SIZE = 7

        attr_reader :diagram, :theme, :model_index

        def initialize(diagram, theme: nil, model_index: {})
          @diagram = diagram
          @model_index = model_index
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

          default_family_for(explicit)
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

        def size_unit_for(element)
          element&.font_size_unit || theme.font_size_unit || "pt"
        end

        def logical_height_for(element)
          element&.font_logical_height if size_unit_for(element) == "pt"
        end

        def weight_for(element)
          bold = element&.font_bold ? 700 : nil
          bold || (theme.themed? ? theme.text_weight_normal : 400)
        end

        def style_for(element)
          return "italic" if element&.font_italic
          return "normal" if element&.style&.key?(:italic)

          diagram.hand_draw ? "italic" : "normal"
        end

        def header_style_for(style, element)
          return style unless diagram.hand_draw && style_for(element) == "italic"

          style == :bold ? :bold_italic : style
        end

        private

        def default_family_for(explicit)
          return HAND_DRAW_FAMILY if diagram.hand_draw

          theme_family_for(explicit) || diagram_default_family || DEFAULT_FONT_FAMILY
        end

        def theme_family_for(explicit)
          return unless theme.themed?
          return theme.font_family || "Carlito" if DEFAULT_MARKER_FAMILIES.include?(explicit)

          theme.element_font_family || theme.font_family
        end

        # Unthemed diagrams without a saved family use Cambria.
        # Saved classifier families still supply the diagram default.
        # A note's explicit font belongs to its body, not sibling classifiers.
        def diagram_default_family
          families = element_families
          return FALLBACK_DEFAULT_FAMILY if families.empty?

          most_common(families)
        end

        FALLBACK_DEFAULT_FAMILY = "Cambria"

        def most_common(values)
          return nil if values.empty?

          tally = tally_values(values)
          tally.max_by { |_, count| count }.first
        end

        def element_families
          placements = (diagram.elements || []).reject do |element|
            model_index[element.model_element_ref].is_a?(Ea::Model::Note)
          end
          placements.map(&:font_family).compact.reject do |family|
            family.empty? || DEFAULT_MARKER_FAMILIES.include?(family)
          end
        end

        def tally_values(values)
          values.each_with_object(Hash.new(0)) { |v, acc| acc[v] += 1 }
        end
      end
    end
  end
end
