# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "honors the stored top edge when the source ray starts below its class", :aggregate_failures do
    cases = [
      [[461, 1010, 100, 80], [374, 772, 210, 190], "EX=-8;EY=40;SX=24;SY=-95;EDGE=1;", "2",
       ["M 168 277 L 159 231", "M 168 245 L 159 231 L 156 247"]],
      [[220, 240, 199, 70], [220, 120, 210, 75], "SX=-6;SY=-37;EX=0;EY=35;EDGE=1;", "0",
       ["M 132 160 L 135 115", "M 140 130 L 135 115 L 128 130"]]
    ]
    cases.each do |source, target, geometry, width, paths|
      result = render_qea_route(source: source, target: target, geometry: geometry,
                                style: "Mode=3;LWidth=#{width};", path: nil, connector_type: "Association")
      expect(result).to eq(paths: paths, markers: []), geometry
    end
  end
end

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  let(:outside_top_ray) do
    { source: [220, 240, 199, 70], target: [220, 120, 210, 75],
      geometry: "SX=-6;SY=-37;EX=0;EY=35;EDGE=1;", style: "Mode=3;LWidth=0;",
      connector_type: "Association", path: nil }
  end

  it "preserves other edges, missed intersections, outside targets and zero offsets" do
    original = ["M 128 158 L 139 115", "M 141 131 L 139 115 L 129 128"]
    cases = [
      [{ geometry: "SX=-6;SY=-37;EX=0;EY=35;EDGE=4;" }, original],
      [{ geometry: "SX=500;SY=-37;EX=0;EY=35;EDGE=1;" },
       ["M 634 158 L 172 115", "M 187 110 L 172 115 L 186 122"]],
      [{ geometry: "SX=-6;SY=-37;EX=500;EY=35;EDGE=1;" },
       ["M 128 158 L 640 112", "M 626 119 L 640 112 L 625 107"]],
      [{ geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=1;" },
       ["M 135 160 L 138 115", "M 143 130 L 138 115 L 131 130"]]
    ]
    cases.each do |changes, paths|
      result = render_qea_route(**outside_top_ray.merge(changes)) do |document|
        expect(document.diagrams.first.connectors.first.style[:stored_top_dock]).to be_nil
      end
      expect(result).to eq(paths: paths, markers: []), changes.inspect
    end
  end
end

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  let(:outside_top_ray) do
    { source: [220, 240, 199, 70], target: [220, 120, 210, 75],
      geometry: "SX=-6;SY=-37;EX=0;EY=35;EDGE=1;", style: "Mode=3;LWidth=0;",
      connector_type: "Association", path: nil }
  end

  it "preserves other routing styles and authored waypoints" do
    original = ["M 128 158 L 139 115", "M 141 131 L 139 115 L 129 128"]
    cases = [
      [{ style: "Mode=2;LWidth=0;" }, original],
      [{ style: "Mode=3;TREE=V;LWidth=0;" }, original],
      [{ style: "Mode=3;LWidth=1;" }, original],
      [{ path: "300:-230;310:-210;" }, original]
    ]
    cases.each do |changes, paths|
      result = render_qea_route(**outside_top_ray.merge(changes)) do |document|
        expect(document.diagrams.first.connectors.first.style[:stored_top_dock]).to be_nil
      end
      expect(result).to eq(paths: paths, markers: []), changes.inspect
    end
  end
end
