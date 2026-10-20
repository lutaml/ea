# frozen_string_literal: true

require "xmi"

module XmiConnectorProxyHelpers
  XML = <<~XML
    <xmi:XMI xmlns:xmi="http://schema.omg.org/spec/XMI/2.1" xmlns:uml="http://schema.omg.org/spec/UML/2.1">
      <uml:Model xmi:type="uml:Model" xmi:id="model" name="Model">
        <packagedElement xmi:type="uml:Package" xmi:id="package" name="Package">
          <packagedElement xmi:type="uml:Class" xmi:id="proxy" name="ProxyConnector"/>
          <packagedElement xmi:type="uml:Class" xmi:id="real" name="ProxyConnector">
            <ownedAttribute xmi:type="uml:Property" xmi:id="attribute" name="value"/>
          </packagedElement>
          <packagedElement xmi:type="uml:Association" xmi:id="association">
            <memberEnd xmi:idref="proxy"/>
            <memberEnd xmi:idref="real"/>
          </packagedElement>
        </packagedElement>
      </uml:Model>
      <xmi:Extension extender="Enterprise Architect">
        <elements>
          <element xmi:idref="proxy" xmi:type="uml:ProxyConnector" name="ProxyConnector"/>
          <element xmi:idref="real" xmi:type="uml:Class" name="ProxyConnector"/>
        </elements>
        <diagrams>
          <diagram xmi:id="diagram">
            <properties name="Proxies" type="Logical"/>
            <elements>
              <element subject="proxy" geometry="Left=10;Top=10;Right=110;Bottom=50;"/>
              <element subject="real" geometry="Left=150;Top=10;Right=250;Bottom=70;"/>
            </elements>
          </diagram>
        </diagrams>
      </xmi:Extension>
    </xmi:XMI>
  XML

  def connector_proxy_document(extension: true)
    xml = extension ? XML : "#{XML.split("<xmi:Extension").first}</xmi:XMI>"
    Ea::Sources::Xmi::Adapter.new(Xmi::Sparx::Root.parse_xml(xml)).to_document
  end

  def connector_proxy_svg(document)
    diagram = document.diagrams.first
    Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id,
                                              document: document).render
  end
end
