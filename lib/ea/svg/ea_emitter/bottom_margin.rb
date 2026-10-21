# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Space EA leaves below the lowest element of an unframed export.
      #
      # EMPIRICAL FIT (no stored selector was found; measured on the 187
      # PLATEAU QEA diagrams whose native SVG is available, 172 match):
      # below the lowest element the canvas keeps 21 + its font size in
      # points (the objectstyle fontsz is in tenths of a point, 0 meaning
      # the 7pt default): 31 for fontsz 100, 30 for 90, 28 for the
      # default. A plain Note, and a Package that draws no "(from
      # Parent)" subtitle, keep the bare 10 margin. Misses: 13 diagrams
      # whose lowest class natively keeps only 10, and 2 outliers.
      class BottomMargin
        BARE = 10
        LINE_ALLOWANCE = 21
        DEFAULT_POINTS = 7

        def self.for(diagram, model_index)
          lowest = lowest_elements(diagram)
          return CanvasAnchor::BOTTOM_MARGIN if lowest.empty?

          lowest.map { |element| of(element, diagram, model_index) }.max
        end

        def self.lowest_elements(diagram)
          placed = (diagram.elements || []).select { |e| e.bounds || e.image_bounds }
          bottom = placed.map { |e| edge(e) }.max
          placed.select { |e| edge(e) == bottom }
        end

        def self.edge(element)
          bounds = element.bounds || element.image_bounds
          bounds.y + bounds.height
        end

        def self.of(element, diagram, model_index)
          model = model_index && model_index[element.model_element_ref]
          return BARE if plain_note?(model) || bare_package?(model, diagram)

          LINE_ALLOWANCE + points(element)
        end

        # QEA keeps the raw objectstyle fontsz; XMI keeps only the GDI
        # pixel height it was rendered at (tenths * 96 / 720, floored).
        def self.points(element)
          tenths = element.style && element.style[:fontsz].to_i
          return tenths / 10 if tenths.to_i.positive?

          pixels = element.font_logical_height.to_i.abs
          pixels.positive? ? (pixels * 0.75).round : DEFAULT_POINTS
        end

        def self.plain_note?(model)
          model.is_a?(Ea::Model::Note) && model.note_type != "Text"
        end

        def self.bare_package?(model, diagram)
          return false unless model.is_a?(Ea::Model::Package)

          parent = model.parent_id
          !(diagram.show_foreign && !parent.to_s.empty? &&
            parent != diagram.package_id)
        end
      end
    end
  end
end
