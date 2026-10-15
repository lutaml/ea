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
