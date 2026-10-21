# frozen_string_literal: true

module D09AF6B8RouteAnchorHelpers
  def d09_fixture_path
    fixtures_path("issue135_route_style/d09af6b8-stored-path-umldi.xmi")
  end

  def d09_fixture_xml
    File.read(d09_fixture_path)
  end

  def d09_xmi_document(xml)
    require "tempfile"

    Tempfile.create(["d09af6b8", ".xmi"]) do |file|
      file.write(xml)
      file.flush
      return Ea::Sources::Xmi::Adapter.from_path(file.path)
    end
  end

  def d09_connector(document)
    document.diagrams.first.connectors.find do |connector|
      connector.relationship_ref.include?("C0837C33")
    end
  end

  def d09_umldi_route(document, connector)
    Ea::Sources::Xmi::DiagramBuilder::UmldiEdges.new(d09_fixture_path)
                                                .route_for(document.diagrams.first.id, connector.relationship_ref)
  end

  def d09_render_document(document)
    diagram = document.diagrams.first
    Nokogiri::XML(Ea::Svg::EaEmitter::Document.new(
      diagram, model_index: document.index_by_id, document: document,
      frame: true
    ).render)
  end

  def d09_label_position(svg, label)
    text = svg.xpath("//*[local-name()='text']").find { |node| node.text == label }
    [text["x"], text["y"]]
  end
end
