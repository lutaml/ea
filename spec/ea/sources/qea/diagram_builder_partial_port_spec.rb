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
      right: [["M 255 433 L 437 434"], ["255 433 265 428 275 433 265 438"]],
      left: [["M 504 472 L 348 470"], ["504 472 494 477 484 472 494 467"]],
      level: [["M 255 265 L 421 265"], ["255 265 265 260 275 265 265 270"]]
    }

    sloped.each do |name, input|
      paths, markers = expected.fetch(name)

      expect(render_qea_route(**input)).to eq({ paths: paths, markers: markers }), name.to_s
    end
  end

  it "uses partial stored ray origins for Associations as well as Aggregations" do
    cases = [
      [sloped[:right], ["M 255 433 L 437 434", "M 422 440 L 437 434 L 422 428"]],
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
                  ["184 387 187 376 197 372 194 383"]]
    cases = [
      ["generalization", { connector_type: "Generalization" },
       ["M 184 387 L 437 110"], ["437 110 431 126 422 118"]],
      ["mode 2", { style: "Mode=2;LWidth=2;" }, *base_route],
      ["width 0", { style: "Mode=3;LWidth=0;" }, ["M 184 388 L 438 109"],
       ["184 388 187 377 197 373 194 384"]],
      ["tree V", { style: "Mode=3;LWidth=2;TREE=V;" }, *base_route],
      ["stored path", { path: "450:-445;" }, ["M 255 434 L 338 434 L 437 434"],
       ["255 434 265 429 275 434 265 439"]],
      ["source port too", { geometry: "EDGE=2;SX=40;SY=0;EX=-156;EY=-163;" },
       ["M 255 432 L 437 434"], ["255 432 265 427 275 432 265 437"]],
      ["overlapping boxes", { target: [300, 51, 312, 465] }, ["M 150 387 L 187 116"],
       ["150 387 146 376 153 367 156 378"]]
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
    slanted = [["M 294 78 L 144 76"], ["294 78 284 83 274 78 284 73"]]
    cases = [
      ["width 2", { style: "Mode=3;LWidth=2;" }, ["M 293 78 L 145 76"],
       ["293 78 283 83 273 78 283 73"]],
      ["width 1", { style: "Mode=3;LWidth=1;" }, *slanted],
      ["generalization", { connector_type: "Generalization" },
       ["M 294 78 L 144 76"], ["144 76 160 70 160 82"]],
      ["mode 2", { style: "Mode=2;LWidth=0;" }, *slanted],
      ["tree V", { style: "Mode=3;LWidth=0;TREE=V;" }, *slanted],
      ["stored path", { path: "300:-135;" }, *slanted],
      ["both ports", { geometry: "SX=-53;SY=2;EX=40;EY=3;EDGE=4;" }, ["M 294 74 L 144 72"],
       ["294 74 284 79 274 74 284 69"]],
      ["overlapping boxes", { target: [300, 100, 109, 70] }, ["M 94 78 L 141 110"],
       ["94 78 105 79 111 89 99 88"]]
    ]

    cases.each do |name, override, paths, markers|
      result = render_qea_route(**width_zero.merge(override))

      expect(result).to eq({ paths: paths, markers: markers }), name
    end
  end

  it "keeps other partial-port inputs on their existing routes" do
    slanted = [["M 173 437 L 422 63"],
               ["173 437 174 426 184 420 183 431"]]
    cases = [
      ["generalization", { connector_type: "Generalization" },
       ["M 173 437 L 422 63"], ["422 63 418 80 408 73"]],
      ["mode 2", { style: "Mode=2;LWidth=2;" }, *slanted],
      ["width 0", { style: "Mode=3;LWidth=0;" }, ["M 254 482 L 423 482"],
       ["254 482 264 477 274 482 264 487"]],
      ["tree V", { style: "Mode=3;LWidth=2;TREE=V;" }, *slanted],
      ["stored path", { path: "400:-457;" }, ["M 255 482 L 356 482 L 422 482"],
       ["255 482 265 477 275 482 265 487"]],
      ["steeper end", { geometry: "EDGE=2;EX=-156;EY=-200;" }, ["M 255 478 L 422 472"],
       ["255 478 265 473 275 477 265 483"]],
      ["both ports", { geometry: "EDGE=2;SX=50;SY=0;EX=-156;EY=-210;" },
       ["M 255 482 L 422 482"], ["255 482 265 477 275 482 265 487"]],
      ["overlapping boxes", { target: [200, 15, 312, 465] }, ["M 145 437 L 155 97"],
       ["145 437 140 427 146 417 150 427"]]
    ]

    cases.each do |name, override, paths, markers|
      result = render_qea_route(**left_source.merge(override))

      expect(result).to eq({ paths: paths, markers: markers }), name
    end
  end
end
