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

  let(:sloped) do
    {
      right: { connector_type: "Aggregation", source: [147, 399, 219, 88],
               target: [550, 51, 312, 465], path: nil,
               geometry: "EDGE=2;EX=-156;EY=-163;", style: "Mode=3;LWidth=2;" },
      left: { connector_type: "Aggregation", source: [529, 400, 219, 88],
              target: [59, 10, 312, 465], path: nil,
              geometry: "EDGE=4;EX=156;EY=-198;", style: "Mode=3;LWidth=2;" },
      level: { connector_type: "Aggregation", source: [781, 289, 219, 88],
               target: [1168, 108, 312, 465], path: nil,
               geometry: "EDGE=2;EX=-156;EY=6;", style: "Mode=3;LWidth=2;" }
    }
  end

  it "draws sloped partial-port lines from the source center to the target ray origin" do
    expected = {
      right: [["M 255 433 L 437 434"], ["255 433 265.03 428.06 275 433.11 264.97 438.05"]],
      left: [["M 504 472 L 348 470"], ["504 472 493.94 476.87 484 471.74 494.06 466.87"]],
      level: [["M 255 265 L 421 265"], ["255 265 265 260 275 265 265 270"]]
    }

    sloped.each do |name, input|
      paths, markers = expected.fetch(name)

      expect(render_qea_route(**input)).to eq({ paths: paths, markers: markers }), name.to_s
    end
  end

  it "uses partial stored ray origins for Associations as well as Aggregations" do
    cases = [
      [sloped[:right], ["M 255 433 L 437 434", "M 421.97 439.92 L 437 434 L 422.03 427.92"]],
      [left_source, ["M 255 482 L 422 482", "M 407 488 L 422 482 L 407 476"]]
    ]
    cases.each do |input, paths|
      expect(render_qea_route(**input.merge(connector_type: "Association")))
        .to eq(paths: paths, markers: [])
    end
  end

  it "keeps other sloped partial-port inputs on their existing routes" do
    base = sloped[:right]
    base_route = [["M 184 387 L 437 110"],
                  ["184 387 187.05 376.24 197.49 372.23 194.44 382.99"]]
    cases = [
      ["generalization", { connector_type: "Generalization" },
       ["M 184 387 L 437 110"], ["437 110 434.01 122.17 425.15 114.08"]],
      ["mode 2", { style: "Mode=2;LWidth=2;" }, *base_route],
      ["width 0", { style: "Mode=3;LWidth=0;" }, ["M 184 388 L 438 109"],
       ["184 388 187.03 377.24 197.46 373.21 194.43 383.97"]],
      ["tree V", { style: "Mode=3;LWidth=2;TREE=V;" }, *base_route],
      ["stored path", { path: "450:-445;" }, ["M 255 434 L 338 434 L 437 434"],
       ["255 434 265 429 275 434 265 439"]],
      ["source port too", { geometry: "EDGE=2;SX=40;SY=0;EX=-156;EY=-163;" },
       ["M 255 432 L 437 434"], ["255 432 265.05 427.11 275 432.22 264.94 437.11"]],
      ["overlapping boxes", { target: [300, 51, 312, 465] }, ["M 150 387 L 187 116"],
       ["150 387 146.4 376.42 152.71 367.18 156.31 377.77"]]
    ]

    cases.each do |name, override, paths, markers|
      result = render_qea_route(**base.merge(override))

      expect(result).to eq({ paths: paths, markers: markers }), name
    end
  end

  # t_diagramlinks 21/67 of basic.qea: width 0, only the source port stored.
  let(:width_zero) do
    { connector_type: "Aggregation", source: [359, 102, 108, 70], target: [100, 100, 109, 70],
      path: nil, geometry: "SX=-53;SY=2;EX=0;EY=0;EDGE=4;", style: "Mode=3;LWidth=0;" }
  end

  it "draws a width-0 single-port straight line level between the facing sides" do
    expect(render_qea_route(**width_zero)).to eq(
      paths: ["M 294 75 L 144 75"], markers: ["294 75 284 80 274 75 284 70"]
    )
  end

  it "keeps other single-source-port inputs on their existing routes" do
    slanted = [["M 294 78 L 144 76"], ["294 78 283.93 82.87 274 77.73 284.07 72.87"]]
    cases = [
      ["width 2", { style: "Mode=3;LWidth=2;" }, ["M 293 78 L 145 76"],
       ["293 78 282.93 82.86 273 77.73 283.07 72.87"]],
      ["width 1", { style: "Mode=3;LWidth=1;" }, *slanted],
      ["generalization", { connector_type: "Generalization" },
       ["M 294 78 L 144 76"], ["144 76 155.08 70.15 154.92 82.15"]],
      ["mode 2", { style: "Mode=2;LWidth=0;" }, *slanted],
      ["tree V", { style: "Mode=3;LWidth=0;TREE=V;" }, *slanted],
      ["stored path", { path: "300:-135;" }, *slanted],
      ["both ports", { geometry: "SX=-53;SY=2;EX=40;EY=3;EDGE=4;" }, ["M 294 74 L 144 72"],
       ["294 74 283.93 78.87 274 73.73 284.07 68.87"]],
      ["overlapping boxes", { target: [300, 100, 109, 70] }, ["M 94 78 L 141 110"],
       ["94 78 105.08 79.49 110.53 89.26 99.45 87.76"]]
    ]

    cases.each do |name, override, paths, markers|
      result = render_qea_route(**width_zero.merge(override))

      expect(result).to eq({ paths: paths, markers: markers }), name
    end
  end

  it "keeps other partial-port inputs on their existing routes" do
    slanted = [["M 173 437 L 422 63"],
               ["173 437 174.38 425.91 184.08 420.35 182.7 431.45"]]
    cases = [
      ["generalization", { connector_type: "Generalization" },
       ["M 173 437 L 422 63"], ["422 63 420.9 75.48 410.91 68.83"]],
      ["mode 2", { style: "Mode=2;LWidth=2;" }, *slanted],
      ["width 0", { style: "Mode=3;LWidth=0;" }, ["M 254 482 L 423 482"],
       ["254 482 264 477 274 482 264 487"]],
      ["tree V", { style: "Mode=3;LWidth=2;TREE=V;" }, *slanted],
      ["stored path", { path: "400:-457;" }, ["M 255 482 L 356 482 L 422 482"],
       ["255 482 265 477 275 482 265 487"]],
      ["steeper end", { geometry: "EDGE=2;EX=-156;EY=-200;" }, ["M 255 478 L 422 472"],
       ["255 478 264.81 472.64 274.99 477.28 265.17 482.64"]],
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
