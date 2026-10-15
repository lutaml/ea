# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do
  include QeaRoutingHelpers

  # Records of the pinned 220 corpus (20251010_current_plateau_v5.1.qea),
  # t_diagramlinks 129/1798 (source left) and 107/1780 (source right):
  # Mode 3, LWidth 2, no TREE, no Path, only the target port stored.
  let(:left_source) do
    { connector_type: "Aggregation", source: [79, 413, 219, 88], target: [467, 15, 312, 465],
      path: nil, geometry: "EDGE=2;EX=-156;EY=-210;", style: "Mode=3;LWidth=2;" }
  end
  let(:right_source) do
    { connector_type: "Aggregation", source: [729, 121, 219, 88], target: [231, 50, 269, 130],
      path: nil, geometry: "EDGE=4;EX=135;EY=-49;", style: "Mode=3;LWidth=2;" }
  end

  it "collapses a one-pixel jog when only one end carries an explicit port" do
    expect(render_qea_route(**left_source)).to eq(
      paths: ["M 255 482 L 422 482"], markers: ["255 482 265 477 275 482 265 487"]
    )
    expect(render_qea_route(**right_source)).to eq(
      paths: ["M 532 154 L 305 154"], markers: ["532 154 522 159 512 154 522 149"]
    )
  end

  it "keeps other partial-port inputs on their existing routes" do
    slanted = [["M 173 437 L 422 63"],
               ["173 437 174.38 425.91 184.08 420.35 182.7 431.45"]]
    cases = [
      ["generalization", { connector_type: "Generalization" },
       ["M 173 437 L 422 63"], ["422 63 420.9 75.48 410.91 68.83"]],
      ["mode 2", { style: "Mode=2;LWidth=2;" }, *slanted],
      ["width 0", { style: "Mode=3;LWidth=0;" }, ["M 173 438 L 423 62"],
       ["173 438 174.37 426.9 184.07 421.35 182.7 432.44"]],
      ["tree V", { style: "Mode=3;LWidth=2;TREE=V;" }, *slanted],
      ["association", { connector_type: "Association" },
       ["M 173 438 L 423 62", "M 419.69 77.81 L 423 62 L 409.7 71.17"], []],
      ["stored path", { path: "400:-457;" }, ["M 255 482 L 356 482 L 422 482"],
       ["255 482 265 477 275 482 265 487"]],
      ["steeper end", { geometry: "EDGE=2;EX=-156;EY=-200;" }, ["M 174 437 L 422 73"],
       ["174 437 175.5 425.92 185.26 420.47 183.76 431.55"]],
      ["both ports", { geometry: "EDGE=2;SX=50;SY=0;EX=-156;EY=-210;" },
       ["M 255 482 L 422 482"], ["255 482 265 477 275 482 265 487"]],
      ["overlapping boxes", { target: [200, 15, 312, 465] }, ["M 145 437 L 155 97"],
       ["145 437 140.3 426.86 145.59 417.01 150.29 427.15"]]
    ]

    cases.each do |name, override, paths, markers|
      result = render_qea_route(**left_source.merge(override))

      expect(result).to eq({ paths: paths, markers: markers }), name
    end
  end
end
