# frozen_string_literal: true

module Ea
  module Sources
    module Xmi
      class DiagramBuilder
        class UmldiEdges
          # Association membership proves which saved role bounds an edge owns.
          class PropertyRoles
            def initialize(doc)
              @doc = doc
            end

            def keys_for(diagram_id, connector_id)
              property_roles.dig(diagram_id, connector_id) || []
            end

            private

            def property_roles
              @property_roles ||= begin
                document = @doc
                declared = declared_properties(document)
                document.xpath("//*[local-name()=\"Diagram\"]").to_h do |diagram|
                  [diagram["id"] || diagram["xmi:id"], diagram_property_roles(diagram, declared)]
                end
              end
            end

            def declared_properties(document)
              members = document.xpath("//*[local-name()='memberEnd']").to_set do |node|
                [node["xmi:idref"], node.parent["xmi:id"]]
              end
              document.xpath("//*[@association][@xmi:id]", "xmi" => "http://www.omg.org/spec/XMI/20131001")
                      .filter_map do |node|
                pair = [node["xmi:id"], node["association"]]
                pair if node.attributes["type"]&.value == "uml:Property" && members.include?(pair)
              end.to_set
            end

            def diagram_property_roles(diagram, declared)
              unique_edges(diagram).transform_values do |edge|
                edge.xpath("./ownedElement[@modelElement]").filter_map do |label|
                  key = target_role_key(label)
                  key if key == :target_role &&
                         declared.include?([label["modelElement"], edge["modelElement"]])
                end
              end
            end

            def unique_edges(diagram)
              diagram.xpath("./ownedElement[@modelElement]")
                     .select { |node| node.attributes["type"]&.value.to_s.end_with?("UMLEdge") }
                     .group_by { |edge| edge["modelElement"] }
                     .select { |_, edges| edges.one? }.transform_values(&:first)
            end

            def target_role_key(label)
              return unless (label["xmi:id"] || label["id"]).to_s.start_with?("EAID_TEL")
              return unless label.attributes["type"]&.value.to_s.end_with?("UMLAssociationEndLabel")

              :target_role
            end
          end
        end
      end
    end
  end
end
