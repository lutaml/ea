# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Compartment
        # Element shape: stroked rect for classifiers, folder
        # silhouette for packages, note silhouette for notes.
        module Shape
          module_function

          def render(context)
            if legend?(context)
              Element::LegendRenderer.render(
                context.bounds,
                legend: context.model_element.legend,
                family: context.family,
                canvas: context.canvas
              )
            elsif context.model_element.is_a?(Ea::Model::Package) ||
                  context.model_element.is_a?(Ea::Model::Note)
              label = package_label(context.model_element)
              stereotype = package_stereotype(context.model_element)
              Element::PackageShapeRenderer.render(
                context.bounds,
                fill: context.fill, stroke: context.stroke,
                stroke_width: context.stroke_width,
                label: label,
                stereotype: stereotype,
                family: context.family, size: context.size,
                size_unit: context.size_unit,
                text_fill: context.text_fill
              )
            elsif hand_draw?(context)
              Element::HandDrawShapeRenderer.render(
                context.bounds,
                fill: context.fill, stroke: context.stroke,
                stroke_width: context.stroke_width
              )
            else
              Element::ShapeRenderer.render(
                context.bounds,
                fill: context.fill, stroke: context.stroke,
                stroke_width: context.stroke_width
              )
            end
          end

          # A Text element with LegendOpts= renders as the legend
          # block rather than a folder silhouette. Dispatch on the
          # presence of the attached Legend payload.
          def legend?(context)
            context.model_element.is_a?(Ea::Model::Note) &&
              context.model_element.legend
          end

          # HandDraw=1 in the diagram StyleEx switches every element
          # to EA's hand-drawn wavy silhouette.
          def hand_draw?(context)
            context.diagram && context.diagram.hand_draw
          end

          def package_label(model_element)
            model_element.name.to_s
          end

          # EA renders a package's applied stereotype above the name
          # inside the tab area when one is set. Returns nil when no
          # stereotype is applied (the common case).
          def package_stereotype(model_element)
            return nil unless model_element.is_a?(Ea::Model::Package)

            refs = model_element.stereotype_refs
            return nil unless refs&.any?

            refs.first.to_s
          end
        end
      end
    end
  end
end
