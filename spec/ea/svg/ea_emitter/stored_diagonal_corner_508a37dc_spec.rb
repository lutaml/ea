# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

RSpec.describe "XMI stored diagonal association corner" do
  include StoredDiagonalCorner508a37dcHelpers

  let(:fixture_path) { fixtures_path("issue135_route_style/stored_diagonal_corner_508a37dc.xmi") }
  let(:expected_waypoints) { [[432, 418], [508, 407], [539, 391]] }

  it "keeps the authored corner and both multiplicity seats through public rendering" do
    connector, svg = stored_diagonal_corner_508a37dc_output(fixture_path)

    expect(connector.waypoints.map { |point| [point.position.x, point.position.y] }).to eq(expected_waypoints)
    expect(connector.style.to_h).to include(mode: "3", lwidth: "2")
    expect(connector.label_boxes[:lrt]).to include("ox" => 47, "oy" => 25, "cx" => 36, "cy" => 14)
    expect(connector.label_boxes[:lrb]).to include("ox" => 19, "oy" => 5, "cx" => 6, "cy" => 14)

    labels = svg.xpath("//*[local-name()='text']").map(&:text)
    expect(labels).to include("+exterior", "1", "0..*")
  end
end
