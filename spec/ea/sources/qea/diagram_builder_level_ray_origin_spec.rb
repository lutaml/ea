# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  it "uses level stored mathematical origins after normalizing computed port jogs" do
    cases = [
      [[410, 200, 192, 91], [710, 0, 343, 465], "SX=97;SY=9;EX=-171;EY=-4;EDGE=2;",
       "M 228 276 L 334 276", "334 276 318 282 318 270"],
      [[280, 240, 168, 72], [540, 194, 343, 465], "EDGE=2;SX=71;SY=11;EX=-169;EY=161;",
       "M 204 111 L 294 111", "294 111 278 117 278 105"]
    ]
    cases.each do |source, target, geometry, path, triangle|
      result = render_qea_route(source: source, target: target, geometry: geometry,
                                style: "Mode=3;LWidth=2;", path: nil)
      expect(result).to eq(paths: [path], markers: [triangle]), geometry
    end
  end
end

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  let(:normalized_ray) do
    { source: [410, 200, 192, 91], target: [710, 0, 343, 465],
      geometry: "SX=97;SY=9;EX=-171;EY=-4;EDGE=2;", path: nil, style: "Mode=3;LWidth=2;" }
  end

  it "preserves unequal origin levels and other authored or styled routing" do
    cases = [
      [{ geometry: "SX=97;SY=8;EX=-171;EY=-4;EDGE=2;" },
       "M 228 278 L 334 278", ["334 278 318 284 318 272"]],
      [{ style: "Mode=1;LWidth=2;" }, "M 228 276 L 334 276", ["334 276 318 282 318 270"]],
      [{ style: "Mode=2;LWidth=2;" }, "M 227 277 L 335 277 L 335 277", []],
      [{ style: "Mode=3;LWidth=0;" }, "M 227 277 L 335 277 L 335 277", []],
      [{ style: "Mode=3;LWidth=1;" }, "M 227 277 L 335 277 L 335 277", []],
      [{ style: "Mode=3;TREE=V;LWidth=2;" }, "M 227 277 L 335 277 L 335 277", []],
      [{ path: "650:-236;670:-236;" }, "M 228 276 L 275 276 L 295 276 L 334 276",
       ["334 276 318 282 318 270"]]
    ]
    cases.each do |changes, path, triangles|
      expect(render_qea_route(**normalized_ray.merge(changes))).to eq(paths: [path], markers: triangles)
    end
  end
end
