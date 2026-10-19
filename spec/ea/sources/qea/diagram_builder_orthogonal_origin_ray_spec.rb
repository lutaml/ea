# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "renders orthogonal mathematical ray docks for dc:25:88, dc:25:229" do
    cases = [
      [[330, 653, 180, 60], [360, 540, 130, 50],
       "SX=0;SY=0;EX=0;EY=0;EDGE=1;SCME=0;SCTR=0;", "Association",
       { paths: ["M 128 153 L 128 91", "M 134 106 L 128 91 L 122 106"], markers: [] },
       [[420, 683], [425, 565]]],
      [[541, 653, 181, 60], [551, 540, 149, 50],
       "SX=0;SY=0;EX=0;EY=0;EDGE=1;SCME=0;SCTR=0;", "Association",
       { paths: ["M 120 153 L 120 91", "M 126 106 L 120 91 L 114 106"], markers: [] },
       [[631, 683], [625, 565]]]
    ]
    cases.each do |entry|
      source, target, geometry, type, expected, origins = entry
      connector = nil
      result = render_qea_route(source: source, target: target, geometry: geometry,
                                connector_type: type, path: nil, style: "Mode=3;TREE=OS;LWidth=2;") do |document|
        connector = document.diagrams.first.connectors.first
      end
      expect(result).to eq(expected)
      expect(connector.style[:orthogonal_origin_ray]).to be(true)
      expect([connector.source_anchor, connector.target_anchor].map { |point| [point.x, point.y] }).to eq(origins)
    end
  end
end

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "renders orthogonal mathematical ray docks for dc:29:131, dc:102:477" do
    cases = [
      [[727, 717, 254, 88], [800, 515, 100, 162],
       "SX=0;SY=0;EX=2;EY=-7;EDGE=1;", "Generalization",
       { paths: ["M 161 241 L 161 202"], markers: ["161 202 167 218 155 218"] },
       [[854, 761], [852, 603]]],
      [[11, 461, 224, 108], [33, 249, 182, 70],
       "SX=-1;SY=0;EDGE=1;EX=0;EY=0;", "Generalization",
       { paths: ["M 147 252 L 147 111"], markers: ["147 111 153 127 141 127"] },
       [[122, 515], [124, 284]]]
    ]
    cases.each do |entry|
      source, target, geometry, type, expected, origins = entry
      connector = nil
      result = render_qea_route(source: source, target: target, geometry: geometry,
                                connector_type: type, path: nil, style: "Mode=3;TREE=OS;LWidth=2;") do |document|
        connector = document.diagrams.first.connectors.first
      end
      expect(result).to eq(expected)
      expect(connector.style[:orthogonal_origin_ray]).to be(true)
      expect([connector.source_anchor, connector.target_anchor].map { |point| [point.x, point.y] }).to eq(origins)
    end
  end
end

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "renders orthogonal mathematical ray docks for dc:102:534, dc:102:569" do
    cases = [
      [[33, 249, 182, 70], [465, 212, 302, 128],
       "EX=151;EY=0;EDGE=2;SX=-41;SY=0;SCME=0;SCTR=0;", "Association",
       { paths: ["M 218 110 L 467 110", "M 452 116 L 467 110 L 452 104"], markers: [] },
       [[83, 284], [767, 276]]],
      [[34, 656, 179, 70], [11, 461, 224, 108],
       "EX=0;EY=0;EDGE=1;SCME=0;SCTR=0;SX=0;SY=0;", "Association",
       { paths: ["M 147 234 L 147 148", "M 153 163 L 147 148 L 141 163"], markers: [] },
       [[123, 691], [123, 515]]]
    ]
    cases.each do |entry|
      source, target, geometry, type, expected, origins = entry
      connector = nil
      result = render_qea_route(source: source, target: target, geometry: geometry,
                                connector_type: type, path: nil, style: "Mode=3;TREE=OS;LWidth=2;") do |document|
        connector = document.diagrams.first.connectors.first
      end
      expect(result).to eq(expected)
      expect(connector.style[:orthogonal_origin_ray]).to be(true)
      expect([connector.source_anchor, connector.target_anchor].map { |point| [point.x, point.y] }).to eq(origins)
    end
  end
end

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "renders orthogonal mathematical ray docks for dc:119:75, dc:119:76" do
    cases = [
      [[95, 376, 182, 70], [527, 347, 302, 128],
       "EX=151;EY=0;EDGE=2;SX=-41;SY=0;SCME=0;SCTR=0;", "Association",
       { paths: ["M 218 104 L 467 104", "M 452 110 L 467 104 L 452 98"], markers: [] },
       [[145, 411], [829, 411]]],
      [[96, 750, 179, 70], [73, 558, 224, 108],
       "EX=0;EY=0;EDGE=1;SCME=0;SCTR=0;SX=0;SY=0;", "Association",
       { paths: ["M 147 231 L 147 148", "M 153 163 L 147 148 L 141 163"], markers: [] },
       [[185, 785], [185, 612]]]
    ]
    cases.each do |entry|
      source, target, geometry, type, expected, origins = entry
      connector = nil
      result = render_qea_route(source: source, target: target, geometry: geometry,
                                connector_type: type, path: nil, style: "Mode=3;TREE=OS;LWidth=2;") do |document|
        connector = document.diagrams.first.connectors.first
      end
      expect(result).to eq(expected)
      expect(connector.style[:orthogonal_origin_ray]).to be(true)
      expect([connector.source_anchor, connector.target_anchor].map { |point| [point.x, point.y] }).to eq(origins)
    end
  end
end

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "renders orthogonal mathematical ray docks for dc:119:77" do
    cases = [
      [[73, 558, 224, 108], [95, 376, 182, 70],
       "SX=-1;SY=0;EDGE=1;EX=0;EY=0;", "Generalization",
       { paths: ["M 147 222 L 147 111"], markers: ["147 111 153 127 141 127"] },
       [[184, 612], [186, 411]]]
    ]
    cases.each do |entry|
      source, target, geometry, type, expected, origins = entry
      connector = nil
      result = render_qea_route(source: source, target: target, geometry: geometry,
                                connector_type: type, path: nil, style: "Mode=3;TREE=OS;LWidth=2;") do |document|
        connector = document.diagrams.first.connectors.first
      end
      expect(result).to eq(expected)
      expect(connector.style[:orthogonal_origin_ray]).to be(true)
      expect([connector.source_anchor, connector.target_anchor].map { |point| [point.x, point.y] }).to eq(origins)
    end
  end
end

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "preserves unsupported placements, missing offsets and authored routing" do
    input = { source: [727, 717, 254, 88], target: [800, 515, 100, 162], path: nil,
              geometry: "SX=0;SY=0;EX=2;EY=-7;EDGE=1;", style: "Mode=3;TREE=OS;LWidth=2;" }
    cases = [
      [{ geometry: "SX=1000;SY=0;EX=2;EY=-7;EDGE=1;" },
       { paths: ["M 1162 286 L 209 122"], markers: ["209 122 226 119 224 131"] }],
      [{ target: [1200, 515, 100, 162] },
       { paths: ["M 266 241 L 507 136"], markers: ["507 136 495 148 490 137"] }],
      [{ geometry: "EX=2;EY=-7;EDGE=1;" },
       { paths: ["M 161 241 L 161 203"], markers: ["161 203 167 219 155 219"] }]
    ]
    cases.each do |changes, expected|
      connector = nil
      result = render_qea_route(**input.merge(changes)) do |document|
        connector = document.diagrams.first.connectors.first
      end
      expect(result).to eq(expected)
      expect(connector.style[:orthogonal_origin_ray]).to be_nil
    end
  end
end

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "preserves unsupported placements, missing offsets and authored routing" do
    input = { source: [727, 717, 254, 88], target: [800, 515, 100, 162], path: nil,
              geometry: "SX=0;SY=0;EX=2;EY=-7;EDGE=1;", style: "Mode=3;TREE=OS;LWidth=2;" }
    cases = [
      [{ path: "854:-700;852:-690;" },
       { paths: ["M 162 241 L 162 225 L 160 215 L 160 203"], markers: ["160 203 166 219 154 219"] }],
      [{ style: "Mode=2;TREE=OS;LWidth=2;" },
       { paths: ["M 161 241 L 161 203"], markers: ["161 203 167 219 155 219"] }]
    ]
    cases.each do |changes, expected|
      connector = nil
      result = render_qea_route(**input.merge(changes)) do |document|
        connector = document.diagrams.first.connectors.first
      end
      expect(result).to eq(expected)
      expect(connector.style[:orthogonal_origin_ray]).to be_nil
    end
  end
end

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "retains the derived port metadata while restoring the original mathematical anchors" do
    connector = nil
    render_qea_route(source: [727, 717, 254, 88], target: [800, 515, 100, 162], path: nil,
                     geometry: "SX=0;SY=0;EX=2;EY=-7;EDGE=1;",
                     style: "Mode=3;TREE=OS;LWidth=2;") do |document|
      connector = document.diagrams.first.connectors.first
    end
    expect(connector.source_port).to be_nil
    expect([connector.target_port.x, connector.target_port.y]).to eq([873, 677])
    expect(connector.waypoints.map { |waypoint| [waypoint.position.x, waypoint.position.y] })
      .to eq([[854, 761], [852, 603]])
  end
end
