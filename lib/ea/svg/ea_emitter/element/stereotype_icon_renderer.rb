# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        # Emits stereotype decorator icons inside an element's body.
        # EA renders a small symbolic polygon (typically a diamond or
        # chevron) when a stereotype provides a custom icon via
        # ShapeScript.
        #
        # Currently provides hardcoded fallback polygons for the most
        # common GML stereotypes (FeatureType, Type) since the source
        # ShapeScript definitions live in EA's encrypted
        # InternalTechnologies (TODO.diagrams/87). Future enhancement:
        # read shapescript from MDG files when available.
        class StereotypeIconRenderer
          # Hardcoded fallback icons keyed by stereotype name.
          # Each entry is [fill, stroke, points_array].
          FALLBACK_ICONS = {
            "FeatureType" => ["#FAF1EC", "#69738C",
                              [[0, -5], [5, 0], [0, 5], [-5, 0]]],
            "Type" => ["#FAF1EC", "#69738C",
                       [[0, -5], [5, 0], [0, 5], [-5, 0]]]
          }.freeze

          # Default position offset from element's center
          OFFSET_X = 0
          OFFSET_Y = 0

          attr_reader :classifier, :bounds, :canvas

          def initialize(classifier:, bounds:, canvas: nil)
            @classifier = classifier
            @bounds = bounds
            @canvas = canvas
          end

          def self.render(classifier:, bounds:, canvas: nil, **_)
            new(classifier: classifier, bounds: bounds, canvas: canvas).to_svg
          end

          # @return [String] SVG polygon fragment, or "" if no icon applies
          def to_svg
            return "" unless classifier && bounds

            spec = FALLBACK_ICONS[stereotype_name]
            return "" unless spec

            fill, stroke, points = spec
            cx = bounds.x + bounds.width / 2 + OFFSET_X
            cy = bounds.y + bounds.height / 2 + OFFSET_Y
            translated = points.map { |x, y| translate_point(cx + x, cy + y) }
            pts_str = translated.map { |x, y| coord(x) + "," + coord(y) }.join(" ")
            %(<polygon points="#{pts_str}" fill="#{fill}" stroke="#{stroke}" stroke-width="1"/>)
          end

          private

          def stereotype_name
            refs = classifier.respond_to?(:stereotype_refs) ? classifier.stereotype_refs : nil
            return refs.first if refs&.any?

            # Walk xref description as a fallback when classifier has no
            # explicit stereotype_refs slot (e.g. raw Ea::Qea::Models::EaObject).
            nil
          end

          def translate_point(x, y)
            return [x, y] unless canvas

            [canvas.translate_x(x), canvas.translate_y(y)]
          end

          def coord(value)
            Ea::Svg::EaEmitter::Canvas.coord(value)
          end
        end
      end
    end
  end
end
