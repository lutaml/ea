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
        # Only MDG-provided ShapeScript is rendered.
        class StereotypeIconRenderer
          attr_reader :classifier, :bounds, :canvas, :mdg_registry

          # @param mdg_registry [Ea::Mdg::Registry, nil] optional
          #   registry to look up MDG-provided ShapeScript for the
          #   classifier's stereotype. When provided and the matching
          #   stereotype has a ShapeScript body, it's parsed and
          #   rendered.
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

            shapescript_svg.to_s
          end

          private

          # Renders MDG-provided ShapeScript for the stereotype.
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

          def stereotype_name
            return nil unless classifier.is_a?(Ea::Model::Classifier)

            refs = classifier.stereotype_refs
            refs&.first
          end
        end
      end
    end
  end
end
