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

          attr_reader :classifier, :bounds, :canvas, :mdg_registry

          # @param mdg_registry [Ea::Mdg::Registry, nil] optional
          #   registry to look up MDG-provided ShapeScript for the
          #   classifier's stereotype. When provided and the matching
          #   stereotype has a ShapeScript body, it's parsed and
          #   rendered. Otherwise falls back to FALLBACK_ICONS.
          def initialize(classifier:, bounds:, canvas: nil, mdg_registry: nil)
            @classifier = classifier
            @bounds = bounds
            @canvas = canvas
            @mdg_registry = mdg_registry
          end

          def self.render(classifier:, bounds:, canvas: nil, **opts)
            new(classifier: classifier, bounds: bounds, canvas: canvas, **opts).to_svg
          end

          # @return [String] SVG fragment, or "" if no icon applies
          def to_svg
            return "" unless classifier && bounds
            return "" unless stereotype_name

            shapescript_svg || fallback_svg
          end

          private

          # Try MDG-provided ShapeScript first.
          # @return [String, nil] SVG fragment from parsed ShapeScript
          def shapescript_svg
            return nil unless mdg_registry

            body = lookup_shapescript(stereotype_name)
            return nil unless body

            shapes = Ea::Shapescript::Parser.parse(body)
            return nil if shapes.empty?

            Ea::Shapescript::Renderer.render(shapes, fill: "#FAF1EC",
                                             stroke: "#69738C")
          end

          # @return [String, nil] ShapeScript source for the stereotype, if any
          def lookup_shapescript(name)
            mdg_registry.documents.each do |doc|
              stereo = (doc.stereotypes || []).find { |s| s.name == name }
              next unless stereo

              notes = stereo.notes
              return notes if notes && notes.include?("shape")
            end
            nil
          end

          # @return [String] hardcoded fallback polygon, or "" if none
          def fallback_svg
            spec = FALLBACK_ICONS[stereotype_name]
            return "" unless spec

            fill, stroke, points = spec
            cx = bounds.x + bounds.width / 2 + OFFSET_X
            cy = bounds.y + bounds.height / 2 + OFFSET_Y
            translated = points.map { |x, y| translate_point(cx + x, cy + y) }
            pts_str = translated.map { |x, y| coord(x) + "," + coord(y) }.join(" ")
            %(<polygon points="#{pts_str}" fill="#{fill}" stroke="#{stroke}" stroke-width="1"/>)
          end

          def stereotype_name
            return nil unless classifier.is_a?(Ea::Model::Classifier)

            refs = classifier.stereotype_refs
            refs&.first
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
