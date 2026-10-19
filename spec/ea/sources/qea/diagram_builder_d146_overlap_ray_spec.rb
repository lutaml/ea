# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do # rubocop:disable Metrics/BlockLength
  include QeaRoutingHelpers

  let(:ray) do
    { connector_type: "Generalization", source: [831, 300, 110, 70], target: [611, 64, 330, 122],
      path: nil, geometry: "EDGE=1;SX=12;SY=34;EX=126;EY=-61;", style: "Mode=2;LWidth=2;" }
  end

  it "docks an empty-Path Mode 2 ray on the shared column and facing outlines" do
    # Diagram 146's _Site -> _CityObject: the native and scoped XMI endpoints agree.
    [nil, ""].each do |path|
      result = render_qea_route(**ray, path: path) do |document|
        points = document.diagrams.first.connectors.first.waypoints.map do |waypoint|
          [waypoint.position.x, waypoint.position.y]
        end
        expect(points).to eq([[898, 299], [898, 187]])
      end
      expect(result).to eq(paths: ["M 322 275 L 322 163"], markers: ["322 163 328 179 316 179"])
    end
  end

  it "uses the facing outlines when the target is below the source" do
    render_qea_route(**ray, source: [831, 64, 110, 70], target: [611, 300, 330, 122],
                            geometry: "EDGE=1;SX=12;SY=-34;EX=126;EY=61;") do |document|
      points = document.diagrams.first.connectors.first.waypoints.map do |waypoint|
        [waypoint.position.x, waypoint.position.y]
      end
      expect(points).to eq([[898, 135], [898, 299]])
    end
  end

  it "translates the route with both boxes" do
    render_qea_route(**ray, source: [931, 350, 110, 70], target: [711, 114, 330, 122]) do |document|
      points = document.diagrams.first.connectors.first.waypoints.map do |waypoint|
        [waypoint.position.x, waypoint.position.y]
      end
      expect(points).to eq([[998, 349], [998, 237]])
    end
  end

  it "preserves origins that do not share the overlap column span" do
    controls = [
      [{ source: [831, 300, 210, 70] }, [[948, 300], [902, 186]]],
      [{ geometry: "EDGE=1;SX=12;SY=34;EX=40;EY=-61;" }, [[898, 300], [816, 186]]]
    ]
    controls.each do |change, expected|
      render_qea_route(**ray.merge(change)) do |document|
        points = document.diagrams.first.connectors.first.waypoints.map do |waypoint|
          [waypoint.position.x, waypoint.position.y]
        end
        expect(points).to eq(expected)
      end
    end
  end

  it "preserves rays whose stored origins are inside or outside the facing border strip" do
    controls = {
      "source interior" => ["EDGE=1;SX=12;SY=33;EX=126;EY=-61;", [[899, 300], [902, 186]]],
      "target interior" => ["EDGE=1;SX=12;SY=34;EX=126;EY=-59;", [[898, 300], [906, 186]]],
      "source outside" => ["EDGE=1;SX=12;SY=36;EX=126;EY=-61;", [[898, 300], [902, 186]]],
      "target outside" => ["EDGE=1;SX=12;SY=34;EX=126;EY=-62;", [[898, 300], [900, 186]]]
    }
    controls.each_value do |geometry, expected|
      render_qea_route(**ray, geometry: geometry) do |document|
        points = document.diagrams.first.connectors.first.waypoints.map do |waypoint|
          [waypoint.position.x, waypoint.position.y]
        end
        expect(points).to eq(expected)
      end
    end
  end
end
