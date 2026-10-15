# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  # Records of the pinned 220 corpus (20251010_current_plateau_v5.1.qea),
  # t_diagramlinks 148/987, 148/988 and 148/995: Mode 3, LWidth 2, no TREE.
  let(:records) do
    {
      generalization: { connector_type: "Generalization",
                        source: [280, 1051, 120, 80], target: [530, 100, 330, 122],
                        path: "206:-1091;206:-151;", geometry: "EDGE=4;EX=-164;EY=9;",
                        style: "Mode=3;LWidth=2;" },
      aggregation: { connector_type: "Aggregation",
                     source: [400, 591, 203, 121], target: [850, 460, 235, 140],
                     path: "632:-624;632:-541;",
                     geometry: "EDGE=2;SX=102;SY=26;EX=-95;EY=-11;", style: "Mode=3;LWidth=2;" },
      single_bend: { connector_type: "Generalization",
                     source: [306, 231, 203, 125], target: [530, 100, 330, 122],
                     path: "367:-152;", geometry: "EDGE=1;SX=-40;SY=49;EX=-163;EY=8;",
                     style: "Mode=3;LWidth=2;" }
    }
  end

  it "enters stored-path ends orthogonally when the adjacent bend is level with the box" do
    expected = {
      generalization: [["M 34 1031 L -39 1031 L -39 91 L 284 91"], ["284 91 273 97 273 85"]],
      aggregation: [["M 239 204 L 267 204 L 267 121 L 484 121"],
                    ["239 204 249 199 259 204 249 209"]],
      single_bend: [["M 96 170 L 96 92 L 258 92"], ["258 92 247 98 247 86"]]
    }

    records.each do |name, input|
      paths, markers = expected.fetch(name)

      expect(render_qea_route(**input)).to eq({ paths: paths, markers: markers }), name.to_s
    end
  end

  let(:corners) do
    {
      wide: { connector_type: "Aggregation", source: [420, 601, 300, 292],
              target: [857, 300, 343, 465], path: "670:-531;",
              geometry: "EDGE=1;SX=100;SY=0;EX=0;EY=0;", style: "Mode=3;LWidth=2;" },
      narrow: { connector_type: "Aggregation", source: [2, 574, 300, 292],
                target: [346, 190, 343, 445], path: "177:-412;",
                geometry: "EDGE=1;SX=25;SY=-2;", style: "Mode=3;LWidth=2;" }
    }
  end

  it "keeps a single stored corner that is level with both boxes" do
    expected = {
      wide: [["M 285 340 L 285 271 L 471 271"], ["285 340 280 330 285 320 290 330"]],
      narrow: [["M 207 423 L 207 262 L 375 262"], ["207 423 202 413 207 403 212 413"]]
    }

    corners.each do |name, input|
      paths, markers = expected.fetch(name)

      expect(render_qea_route(**input)).to eq({ paths: paths, markers: markers }), name.to_s
    end
  end

  it "keeps other single-corner inputs on their existing routes" do
    base = corners[:wide]
    flat = [["M 336 456 L 471 375"], ["336 456 342 446.57 353.15 445.71 347.15 455.14"]]
    cases = [
      ["mode 2", { style: "Mode=2;LWidth=2;" }, *flat],
      ["width 0", { style: "Mode=3;LWidth=0;" }, ["M 335 456 L 472 374"],
       ["335 456 341.01 446.57 352.16 445.73 346.15 455.15"]],
      ["tree V", { style: "Mode=3;LWidth=2;TREE=V;" }, *flat],
      ["association", { connector_type: "Association" },
       ["M 335 456 L 472 374", "M 462.21 386.85 L 472 374 L 456.05 376.56"], []],
      ["generalization", { connector_type: "Generalization" },
       ["M 285 340 L 285 271 L 471 271"], ["471 271 460 277 460 265"]],
      ["corner not level with source", { path: "800:-531;" }, *flat],
      ["corner not level with target", { path: "670:-200;" }, *flat],
      ["two corners", { path: "670:-531;700:-531;" }, *flat]
    ]

    cases.each do |name, override, paths, markers|
      result = render_qea_route(**base.merge(override))

      expect(result).to eq({ paths: paths, markers: markers }), name
    end
  end

  it "keeps other stored-path inputs on their existing routes" do
    base = records[:generalization]
    kept = [["M 35 991 L -39 1031 L -39 91 L 285 162"],
            ["285 162 272.97 165.51 275.54 153.78"]]
    cases = [
      ["tree V", { style: "Mode=3;LWidth=2;TREE=V;" }, *kept],
      ["tree H", { style: "Mode=3;LWidth=2;TREE=H;" }, *kept],
      ["mode 2", { style: "Mode=2;LWidth=2;" }, *kept],
      ["width 0", { style: "Mode=3;LWidth=0;" }, *kept],
      ["width 1", { style: "Mode=3;LWidth=1;" }, *kept],
      ["association", { connector_type: "Association" },
       ["M 35 1031 L -39 1031 L -39 91 L 285 92", "M 269.98 97.95 L 285 92 L 270.02 85.95"], []],
      ["source bend not level", { path: "206:-1000;206:-151;" },
       ["M 35 990 L -39 940 L -39 91 L 284 91"], ["284 91 273 97 273 85"]],
      ["source bend inside box", { path: "320:-1091;206:-151;" },
       ["M 75 991 L 75 1031 L -39 91 L 284 91"], ["284 91 273 97 273 85"]],
      ["no stored path", { path: nil },
       ["M 103 990 L 284 119"], ["284 119 287.64 130.99 275.89 128.55"]]
    ]

    cases.each do |name, override, paths, markers|
      result = render_qea_route(**base.merge(override))

      expect(result).to eq({ paths: paths, markers: markers }), name
    end
  end
end
