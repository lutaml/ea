# frozen_string_literal: true

require "spec_helper"
require "ea"
require "nokogiri"

RSpec.describe "XMI width-zero Association ray labels" do
  let(:document) { Ea::Sources::Xmi::Adapter.from_path(fixtures_path("association_stored_ray_a081c63e.xmi")) }
  let(:diagram) { document.diagrams.first }
  let(:connector) do
    diagram.connectors.find { |entry| entry.id.end_with?("EAID_E7FFECEB_996C_45b0_8E47_A56B4834C7DF") }
  end

  it "classifies the saved ray without replacing its authored UMLDI route" do
    expect(connector.style.to_h).to include(umldi_route: true, stored_association_ray: true,
                                            association_ray_outline: true)
    expect(connector.waypoints.map { |point| [point.position.x, point.position.y] })
      .to eq([[839, 480], [755, 370]])
    expect([connector.source_anchor, connector.target_anchor, connector.source_port, connector.target_port])
      .to eq([nil, nil, nil, nil])
    expect(connector.label_boxes[:lrt]).to include("cx" => 127, "cy" => 35, "ox" => 0, "oy" => 8, "alignment" => 1)

    svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id,
                                                    document: document).render
    role = Nokogiri::XML(svg).css("text").find { |text| text.text == "+relativeGMLGeometry" }
    expect([role["x"].to_f, role["y"].to_f]).to eq([56, 183])
  end
end

RSpec.describe "XMI horizontal saved Association preservation" do
  it "preserves a separate horizontal UMLDI Association and its stored labels" do
    held_out = Ea::Sources::Xmi::Adapter.from_path(fixtures_path("basic.xmi"))
    other_diagram = held_out.diagrams.find { |entry| entry.id.include?("78030266") }
    other = other_diagram.connectors.find do |entry|
      entry.id.end_with?("EAID_AF2AA131_EEB1_4de7_98F5_670D6EE4A52B")
    end
    expect(other.style[:umldi_route]).to be(true)
    expect(other.style[:stored_association_ray]).to be(true)
    expect(other.waypoints.map { |point| [point.position.x, point.position.y] })
      .to eq([[217, 137], [399, 137]])
    expect(other.label_boxes.keys).to contain_exactly(:llb, :lmt, :lrb)
    expect(other.label_boxes[:lmt]).to include("ox" => -8, "oy" => -4, "cx" => 38, "cy" => 11)
    expect([other.source_anchor, other.target_anchor, other.source_port, other.target_port])
      .to eq([nil, nil, nil, nil])
  end
end
