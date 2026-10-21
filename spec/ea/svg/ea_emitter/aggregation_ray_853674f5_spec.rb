# frozen_string_literal: true

require "spec_helper"
require "ea"
require "nokogiri"
require "xmi"

module AggregationRay853674F5Support
  def source_path
    fixtures_path("aggregation_ray_853674f5.xmi")
  end

  def source_xml
    Nokogiri::XML(File.read(source_path))
  end

  def source_connector
    source_xml.at_xpath(
      "//*[local-name()='element' and @subject='EAID_C0837C33_802E_41cd_A63A_31684137BAE7']"
    )
  end

  def connector_and_diagram
    document = Ea::Sources::Xmi::Adapter.from_path(source_path)
    diagram = document.diagrams.find do |entry|
      entry.id.end_with?("EAID_853674F5_7DC9_4aae_809B_5728098B5D5B")
    end
    connector = diagram.connectors.find do |entry|
      entry.id.end_with?("EAID_C0837C33_802E_41cd_A63A_31684137BAE7")
    end
    [document, diagram, connector]
  end

  def expect_saved_source_contract
    source_end = source_xml.at_xpath(
      "//*[local-name()='ownedAttribute' and @xmi:id='EAID_src837C33_802E_41cd_A63A_31684137BAE7']"
    )
    expect(source_end["aggregation"]).to eq("shared")
    expect(source_connector["geometry"]).to include("Path=553:-129$")
    expect(source_connector["style"]).to include("Mode=1", "LWidth=2")
  end

  def rendered_diagram
    document, diagram, = connector_and_diagram
    Ea::Svg::EaEmitter::Document.new(
      diagram,
      model_index: document.index_by_id,
      document: document
    ).render
  end

  def expect_connector_contract
    _, _, connector = connector_and_diagram
    expect(connector_contract(connector)).to eq(
      type: "Aggregation",
      ray_outline: true,
      waypoints: [[911, 218], [702, 218]]
    )
  end

  def connector_contract(connector)
    {
      type: connector.connector_type,
      ray_outline: connector.style[:association_ray_outline],
      waypoints: connector.waypoints.map do |point|
        [point.position.x, point.position.y]
      end
    }
  end

  def expect_rendered_route_and_label
    rendered = Nokogiri::XML(rendered_diagram)
    expect(route_data(rendered)).to eq("M 568 86 L 361 86")
    expect(label_position(rendered)).to eq(["505.00", "100.00"])
  end

  def route_data(rendered)
    rendered.at_xpath("//*[local-name()='path' and @d='M 568 86 L 361 86']")&.[]("d")
  end

  def label_position(rendered)
    labels = rendered.xpath("//*[local-name()='text']").select do |text|
      text.text.strip == "1..*"
    end
    expect(labels.length).to eq(1)
    label = labels.first
    [label["x"], label["y"]]
  end

  def expect_emitted_route_and_multiplicity
    expect_connector_contract
    expect_rendered_route_and_label
  end
end

RSpec.describe "XMI stored aggregation ray 853674F5" do
  include AggregationRay853674F5Support

  it "keeps the saved association source contract" do
    expect_saved_source_contract
  end

  it "emits the stored route and unique aggregation multiplicity" do
    expect_emitted_route_and_multiplicity
  end
end
