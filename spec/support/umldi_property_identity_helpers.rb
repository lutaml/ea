# frozen_string_literal: true

require "nokogiri"
require "tempfile"

module UmldiPropertyIdentityHelpers
  SOURCE = <<~XML
    <xmi:XMI xmlns:xmi="http://www.omg.org/spec/XMI/20131001" xmlns:uml="http://www.omg.org/spec/UML/20161101" xmlns:umldi="http://www.omg.org/spec/UML/20161101/UMLDI">
      <packagedElement xmi:type="uml:Association" xmi:id="association">
        <memberEnd xmi:idref="property"/>
      </packagedElement>
      <ownedAttribute xmi:type="uml:Property" xmi:id="property" association="association"/>
      <umldi:Diagram xmi:id="diagram">
        <ownedElement xmi:type="umldi:UMLEdge" modelElement="association">
          <ownedElement xmi:type="umldi:UMLAssociationEndLabel" xmi:id="EAID_TEL_label" modelElement="property">
            <bounds x="767" y="288" width="86" height="13"/>
          </ownedElement>
        </ownedElement>
      </umldi:Diagram>
    </xmi:XMI>
  XML

  def with_property_label_identity(change = nil)
    xml = Nokogiri::XML(SOURCE)
    change&.call(xml)
    Tempfile.create(["umldi-property-identity", ".xmi"]) do |file|
      file.write(xml.to_xml)
      file.flush
      yield Ea::Sources::Xmi::DiagramBuilder::UmldiEdges.new(file.path)
    end
  end
end
