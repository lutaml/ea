# frozen_string_literal: true

require "tempfile"

module Issue135AssociationSourceContractHelpers
  def issue135_generic_source_document
    root = Xmi::Sparx::Root.parse_xml(File.read(fixtures_path("basic.xmi")))
    root.extension = nil
    Ea::Sources::Xmi::Adapter.new(root).to_document
  end

  def issue135_source_endpoint_texts(document, association)
    renderer = Ea::Svg::EaEmitter::Label::EndLabel.new(
      canvas: nil, model_index: document.index_by_id, document: document,
      theme: Ea::Theme::Registry.default, font_family: "Carlito", font_size: 7, font_unit: "pt"
    )
    connector = Ea::Model::DiagramConnector.new(id: "generic", relationship_ref: association.id)
    svg = renderer.texts(text_box: { "ox" => 10, "oy" => 10 }, mult_box: { "ox" => 10, "oy" => 30 },
                         anchor: [0, 0], connector: connector, end_kind: :source).join
    Nokogiri::XML("<g>#{svg}</g>").css("text").map(&:text)
  end

  def issue135_source_class_c(document)
    document.classifiers.find { |item| item.id == "EAID_99DB48BA_556A_4975_9499_F208F7575FCC" }
  end

  def issue135_source_texts(document, diagram_prefix)
    diagram = document.diagrams.find { |item| item.id.start_with?("EAID_#{diagram_prefix}") }
    svg = Ea::Svg::EaEmitter::Document.new(diagram, document: document,
                                                    model_index: document.index_by_id).render
    Nokogiri::XML(svg).remove_namespaces!.css("text").map(&:text)
  end

  def issue135_named_source_document
    xml = Nokogiri::XML(File.read(fixtures_path("basic.xmi")))
    endpoint = xml.at_xpath("//*[@xmi:id='EAID_dstCF64D9_3CAA_41e2_862C_8C4A9BA09AC2']")
    issue135_copy_source_attributes(endpoint)
    issue135_name_source_attribute(endpoint)
    Tempfile.create(["issue135-named-association-end", ".xmi"]) do |file|
      file.write(xml.to_xml)
      file.flush
      Ea::Sources::Xmi::Adapter.from_path(file.path)
    end
  end

  def issue135_copy_source_attributes(endpoint)
    empty_endpoint = endpoint.dup
    empty_endpoint["xmi:id"] = "empty-association-end"
    empty_endpoint["name"] = ""
    endpoint.add_next_sibling(empty_endpoint)
    ordinary = endpoint.dup
    ordinary["xmi:id"] = "unnamed-ordinary-attribute"
    ordinary.remove_attribute("association")
    endpoint.add_next_sibling(ordinary)
  end

  def issue135_name_source_attribute(endpoint)
    endpoint["name"] = "typedBoundary"
    endpoint["visibility"] = "public"
    endpoint.add_child('<lowerValue xmi:type="uml:LiteralInteger" value="0"/>')
    endpoint.add_child('<upperValue xmi:type="uml:LiteralUnlimitedNatural" value="*"/>')
  end
end
