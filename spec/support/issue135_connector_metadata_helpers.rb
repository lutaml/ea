# frozen_string_literal: true

require_relative "xmi_connector_end_helpers"

module Issue135ConnectorMetadataHelpers
  include XmiConnectorEndHelpers

  def metadata_midpoint(connector)
    renderer = Ea::Svg::EaEmitter::Label::MidpointLabel.new(
      canvas: nil, model_index: {}, font_family: "Carlito", font_size: 7, font_unit: "pt"
    )
    svg = renderer.text_for(connector, [[0, 0], [100, 0]])
    Nokogiri::XML(svg).at_xpath("//text")&.text
  end

  def metadata_without_file(xrefs)
    connector = Struct.new(:idref, :xrefs).new("connector", Struct.new(:value).new(xrefs))
    Ea::Sources::Xmi::DiagramBuilder::ConnectorMetadata.new(nil).for(connector)
  end

  def metadata_custom_property(value, name: "isSubstitutable")
    "$XREFPROP=$NAM=CustomProperties$NAM;$TYP=connector property$TYP;" \
      "$DES=@PROP=@NAME=#{name}@ENDNAME;@TYPE=Boolean@ENDTYPE;" \
      "@VALU=#{value}@ENDVALU;@ENDPROP;$DES;$ENDXREF;"
  end

  def metadata_connector(source: nil, target: nil, value: nil)
    xml = Nokogiri::XML(basic_xmi_text)
    node = xml.at_xpath("//*[local-name()='connectors']/*[local-name()='connector']")
    node.at_xpath("./source/role")["stereotype"] = source if source
    node.at_xpath("./target/role")["stereotype"] = target if target
    node.at_xpath("./xrefs")["value"] = metadata_custom_property(value) if value
    connector_in(xml.to_xml, XmiConnectorEndHelpers::LINK_A).last
  end
end
