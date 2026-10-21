# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

RSpec.describe "XMI plain source seat metadata" do
  include D159XmiSeatHelpers
  let(:fixture) { File.read(fixtures_path("issue135_route_style/d159-plain-source-seat.xmi")) }

  it "marks and renders the source seat for the D159 saved XMI contract" do
    document = d159_xmi_adapter(fixture)
    diagram = document.diagrams.first
    connector = diagram.connectors.first
    svg = Ea::Svg::EaEmitter::Document.new(
      diagram, model_index: document.index_by_id, document: document,
      frame: true
    ).render
    role = Nokogiri::XML(svg).xpath("//*[local-name()='text']").find do |node|
      node.text == "+developmentProject"
    end

    expect(diagram.name).to eq("UrgentUrbanRenewalprogram")
    # The position is the saved LLT/QEA seat, not a claim of native pixel parity.
    expect([role["x"], role["y"]]).to eq(["79.00", "357.00"])
    expect(connector.style.to_h).to include(plain_source_seat: true)
  end

  it "does not mark authored paths, regenerated contexts, or other connector types" do
    authored_path = fixture.sub("Path=;", "Path=1:-1$;")
    regenerated_context = fixture.sub("SuppressFOC=1", "SuppressFOC=0")
    other_type = fixture.sub('ea_type="Aggregation"', 'ea_type="Association"')

    [authored_path, regenerated_context, other_type].each do |xml|
      connector = d159_xmi_adapter(xml).diagrams.first.connectors.first
      expect(connector.style.to_h).not_to have_key(:plain_source_seat)
    end
  end
end

RSpec.describe "XMI plain target seat metadata" do
  include D785XmiSeatHelpers
  let(:fixture) { File.read(fixtures_path("issue135_route_style/d785-plain-target-seat.xmi")) }

  it "marks and renders the target seat for the D785 saved XMI contract" do
    document = d785_xmi_adapter(fixture)
    diagram = document.diagrams.first
    connector = diagram.connectors.first
    svg = Ea::Svg::EaEmitter::Document.new(
      diagram, model_index: document.index_by_id, document: document,
      frame: true
    ).render
    role = Nokogiri::XML(svg).xpath("//*[local-name()='text']").find do |node|
      node.text == "+lod0MultiPoint"
    end

    expect(diagram.id).to eq("EAID_785226C1_12B1_4104_A4C1_F19B70B9FB71")
    expect(connector.style.to_h).not_to have_key(:plain_source_seat)
    expect([role["x"], role["y"]]).to eq(["237.00", "66.00"])
    expect(connector.style.to_h).to include(plain_target_seat: true)
  end
end

RSpec.describe "D785 target seat preservation" do
  include D785XmiSeatHelpers
  let(:fixture) { File.read(fixtures_path("issue135_route_style/d785-plain-target-seat.xmi")) }

  it "preserves the target-seat guards for saved paths and context diagrams" do
    authored_path = fixture.sub("Path=;", "Path=20:-10$;")
    regenerated_context = fixture.sub("SuppressFOC=1", "SuppressFOC=0")

    expect(authored_path).not_to eq(fixture)
    expect(regenerated_context).not_to eq(fixture)

    [authored_path, regenerated_context].each do |xml|
      connector = d785_xmi_adapter(xml).diagrams.first.connectors.first
      expect(connector.style.to_h).not_to have_key(:plain_target_seat)
    end
  end
end
