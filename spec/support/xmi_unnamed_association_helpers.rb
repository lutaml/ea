# frozen_string_literal: true

module XmiUnnamedAssociationHelpers
  def unnamed_association_texts(document, prefix)
    diagram = document.diagrams.find { |item| item.id.include?(prefix) }
    svg = Ea::Svg::EaEmitter::Document.new(
      diagram, model_index: document.index_by_id, document: document
    ).render
    Nokogiri::XML(svg).remove_namespaces!.xpath("//text").map(&:text)
  end

  def named_association_document
    xml = File.read(fixtures_path("basic.xmi"))
              .sub('xmi:id="EAID_dstCF64D9_3CAA_41e2_862C_8C4A9BA09AC2"',
                   'xmi:id="EAID_dstCF64D9_3CAA_41e2_862C_8C4A9BA09AC2" name="retained"')
    root = Xmi::Sparx::Root.parse_xml(xml)
    Ea::Sources::Xmi::Adapter.new(root, fixtures_path("basic.xmi")).to_document
  end
end
