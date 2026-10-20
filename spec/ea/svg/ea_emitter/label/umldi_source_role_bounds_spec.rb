# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe "UMLDI source role bounds of declared properties on 348EE46E" do
  let(:path) { fixtures_path("issue135_route_style/348e-lod0-roles.xmi") }
  let(:document) { Ea::Sources::Xmi::Adapter.from_path(path) }
  let(:diagram) { document.diagrams.first }

  let(:roles) do
    {
      "+lod0RoofEdge" => [487.0, 307.0],
      "+lod0FootPrint" => [543.0, 225.0],
      "+bldgKeyValuePairAttribute" => [442.0, 388.0],
      "+largeCustomerFacilityAttribute" => [336.0, 515.0]
    }
  end

  def source_role_box(xml, connector)
    xml.at_xpath("//*[local-name()='Diagram']/ownedElement[@modelElement='#{connector.relationship_ref}']" \
                 "/ownedElement[starts-with(@xmi:id, 'EAID_SEL')]/*[local-name()='bounds']",
                 "xmi" => "http://www.omg.org/spec/XMI/20131001")
  end

  def supply_source_role_bounds
    xml = Nokogiri::XML(File.read(path))
    diagram.connectors.each do |connector|
      box = source_role_box(xml, connector)
      next unless box

      bounds = %w[x y width height].to_h { |name| [name.to_sym, Integer(box[name])] }
      connector.umldi_label_bounds = connector.umldi_label_bounds.merge(source_role: bounds)
    end
  end

  def rendered_texts
    svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id, document: document).render
    Nokogiri::XML(svg).xpath("//*[local-name()='text']").map { |node| [node.text, [node["x"].to_f, node["y"].to_f]] }
  end

  it "seats the declared source roles at their saved UMLDI bounds" do
    supply_source_role_bounds

    expect(rendered_texts.to_h.slice(*roles.keys)).to eq(roles)
  end

  it "keeps the ALN1 stereotype centred under its saved role bounds" do
    supply_source_role_bounds

    expect(rendered_texts.select { |text, _| text == "«property»" }.map(&:last))
      .to include([479.0, 400.0], [543.0, 237.0], [487.0, 319.0])
  end
end
