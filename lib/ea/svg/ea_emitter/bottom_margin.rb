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
      # Parent)" subtitle, keep the bare 10 margin, as does a classifier
      # or instance of the diagram's own package. Misses: 2 outliers.
      class BottomMargin
        BARE = 10
        LINE_ALLOWANCE = 21
        HOME_TEXT_ALLOWANCE = 13
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
          return home_text_margin(element) if home_text?(model, diagram)
          return BARE if plain_note?(model) || bare_package?(model, diagram) ||
                         home_element?(model, diagram)

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

        # An element of the diagram's own package (a classifier, nested
        # in an owner class or not, or an instance) draws no "(from
        # Package)" row under its name, so EA keeps only the bare margin
        # below it. EMPIRICAL FIT, checked on: the 7 PLATEAU diagrams
        # whose lowest class is in the diagram's package (all natively
        # 10) against the 84 foreign ones (all 28..31); basic.qea
        # 3B8BD087 and D14AA320 (lowest an own-package "Object B"
        # instance) and 372F7F7B, 4FC1D352, 6D0349D5 (lowest a Klass
        # nested in "Class A.x" / "Class B" of the own package), all
        # natively 10; and the foreign basic instances, natively 28.
        def self.home_element?(model, diagram)
          (model.is_a?(Ea::Model::Classifier) ||
            model.is_a?(Ea::Model::InstanceSpecification)) &&
            !diagram.package_id.to_s.empty? &&
            model.package_id == diagram.package_id
        end

        # A Text element of the diagram's own package keeps 13 + its
        # font size in points (22 at 9pt) instead of the foreign 21 + size.
        # EMPIRICAL FIT on a single sample (PLATEAU 2E98EA19, fontsz 90,
        # natively 22); the 8 foreign Text cases (28..30) are unaffected.
        def self.home_text?(model, diagram)
          model.is_a?(Ea::Model::Note) && model.note_type == "Text" &&
            !diagram.package_id.to_s.empty? &&
            model.package_id == diagram.package_id
        end

        def self.home_text_margin(element)
          HOME_TEXT_ALLOWANCE + points(element)
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
