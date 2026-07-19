# frozen_string_literal: true

module Ea
  module Sources
    module Xmi
      # Translates XMI uml:Diagram elements into Ea::Model::Diagram
      # instances. Coordinates come from the UML-DI owned_element
      # bounds; element references come from the model_element
      # attribute.
      class DiagramBuilder
        attr_reader :root

        def initialize(root)
          @root = root
        end

        def build_all
          diagrams = Array(root.model.diagram)
          diagrams.map { |d| build_one(d) }
        end

        def build_one(diagram)
          id = IdNormalizer.from_xmi_id(diagram.id)
          ext_diagram = extension_diagram_for(id)
          Ea::Model::Diagram.new(
            id: id,
            name: ext_diagram&.properties&.name,
            package_id: ext_diagram&.model&.package,
            diagram_type: ext_diagram&.properties&.type&.split(":")&.last&.downcase,
            bounds: bounds_for(diagram),
            elements: build_elements(diagram, id),
            connectors: [],
            annotations: AnnotationBuilder.from_element(diagram, id)
          )
        end

        private

        def extension_diagram_for(diagram_id)
          return nil unless root.extension&.diagrams

          root.extension.diagrams.diagram.find { |d| d.id == diagram_id }
        end

        def bounds_for(diagram)
          first_bounds = diagram.owned_element.flat_map(&:bounds).first
          return nil unless first_bounds

          Ea::Model::Bounds.new(
            x: first_bounds.x || 0,
            y: first_bounds.y || 0,
            width: first_bounds.width || 0,
            height: first_bounds.height || 0
          )
        end

        def build_elements(diagram, owner_diagram_id)
          diagram.owned_element.flat_map do |oe|
            oe.bounds.each_with_index.map do |bnd, idx|
              build_element(oe, bnd, owner_diagram_id, idx)
            end
          end
        end

        def build_element(owned_element, bounds, diagram_id, idx)
          Ea::Model::DiagramElement.new(
            id: IdNormalizer.synthetic_id(diagram_id, "elem", idx.to_s),
            diagram_id: diagram_id,
            model_element_ref: IdNormalizer.from_xmi_id(owned_element.model_element),
            bounds: Ea::Model::Bounds.new(
              x: bounds.x || 0,
              y: bounds.y || 0,
              width: bounds.width || 0,
              height: bounds.height || 0
            ),
            style: {}
          )
        end
      end
    end
  end
end
