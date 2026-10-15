# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Qea::DiagramBuilder do # rubocop:disable Metrics/BlockLength
  include QeaRoutingHelpers

  it "offsets only width-2 parent-above multi-bend routes, preserving interior bends" do # rubocop:disable Metrics/BlockLength
    cases = [
      [{ path: "150:-250;450:-250;", style: "TREE=V;LWidth=2;" },
       "M 85 239 L 85 190 L 385 190 L 385 141"],
      [{ path: "150:-270;250:-270;250:-230;450:-230;", style: "TREE=V;LWidth=2;" },
       "M 85 239 L 85 210 L 185 210 L 185 170 L 385 170 L 385 141"],
      [{ path: "450:-350;", style: "TREE=LV;LWidth=2;",
         geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=2;" },
       "M 235 290 L 385 290 L 385 140"],
      [{ path: "450:-250;", style: "LWidth=2;" },
       "M 235 240 L 385 190 L 385 140"],
      [{ path: "150:-250;450:-250;", style: "TREE=V;LWidth=2;",
         source: [100, 100, 200, 100], target: [400, 300, 200, 100] },
       "M 135 40 L 85 190 L 385 190 L 435 240"],
      [{ path: "", style: "TREE=V;LWidth=2;" }, "M 211 239 L 358 141"]
    ]
    [
      [199, "M 85 239 L 85 139 L 385 139 L 385 140"],
      [200, "M 85 239 L 85 140 L 385 140 L 385 140"],
      [201, "M 85 239 L 85 141 L 385 141 L 385 140"],
      [202, "M 85 239 L 85 142 L 385 142 L 385 141"],
      [298, "M 85 239 L 85 238 L 385 238 L 385 141"],
      [299, "M 85 240 L 85 239 L 385 239 L 385 141"],
      [300, "M 85 240 L 85 240 L 385 240 L 385 141"],
      [301, "M 85 240 L 85 241 L 385 241 L 385 141"]
    ].each do |bend, expected|
      cases << [{ path: "150:-#{bend};450:-#{bend};", style: "TREE=V;LWidth=2;" }, expected]
    end
    ["0", "1", "3", "2.0", nil].each do |width|
      style = width ? "TREE=V;LWidth=#{width};" : "TREE=V;"
      cases << [{ path: "150:-250;450:-250;", style: style },
                "M 85 240 L 85 190 L 385 190 L 385 140"]
    end

    cases.each do |input, expected|
      result = render_qea_route(**input)

      expect(result[:paths]).to eq([expected]), "route input: #{input.inspect}"
    end
  end

  # Each row: input, expected route paths, expected marker polygons. The
  # diamond sits on the source end, so its tip follows the first point.
  it "docks only width-2 parent-above bent Aggregations like Generalizations" do # rubocop:disable Metrics/BlockLength
    bent = "150:-250;450:-250;"
    docked_tip = "85 239 80 229 85 219 90 229"
    stale = ["M 135 240 L 85 190 L 385 190 L 435 40"]
    stale_tip = "135 240 124.39 236.46 120.86 225.86 131.46 229.39"
    cases = [
      [{ path: bent, style: "TREE=V;LWidth=2;" },
       ["M 85 239 L 85 190 L 385 190 L 385 141"], [docked_tip]],
      [{ path: "150:-270;250:-270;250:-230;450:-230;", style: "TREE=V;LWidth=2;" },
       ["M 85 239 L 85 210 L 185 210 L 185 170 L 385 170 L 385 141"], [docked_tip]],
      [{ path: bent, style: "TREE=V;LWidth=2;", geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=2;" },
       ["M 235 290 L 85 190 L 385 190 L 535 90"],
       ["235 290 223.91 288.61 218.36 278.91 229.45 280.29"]],
      [{ path: bent, style: "TREE=V;LWidth=2;", connector_type: "Association" },
       [*stale, "M 435.95 56.13 L 435 40 L 424.56 52.33"], []],
      [{ path: bent, style: "TREE=V;LWidth=2;", geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=4;",
         source: [100, 300, 200, 100], target: [100, 100, 200, 100] },
       ["M 135 239 L 135 141"], ["135 239 130 229 135 219 140 229"]],
      [{ path: "450:-250;", style: "TREE=V;LWidth=2;" },
       ["M 135 240 L 385 190 L 435 40"],
       ["135 240 143.83 233.14 154.61 236.08 145.79 242.94"]],
      [{ path: bent, style: "TREE=V;LWidth=2;",
         source: [100, 100, 200, 100], target: [400, 300, 200, 100] },
       ["M 135 40 L 85 190 L 385 190 L 435 240"],
       ["135 40 136.58 51.07 128.68 58.97 127.09 47.91"]],
      [{ path: "150:-199;450:-199;", style: "TREE=V;LWidth=2;" },
       ["M 85 239 L 85 139 L 385 139 L 435 40"], [docked_tip]],
      [{ path: "150:-200;450:-200;", style: "TREE=V;LWidth=2;" },
       ["M 85 239 L 85 140 L 385 140 L 435 40"], [docked_tip]],
      [{ path: "150:-201;450:-201;", style: "TREE=V;LWidth=2;" },
       ["M 85 239 L 85 141 L 385 141 L 385 140"], [docked_tip]],
      [{ path: "150:-202;450:-202;", style: "TREE=V;LWidth=2;" },
       ["M 85 239 L 85 142 L 385 142 L 385 141"], [docked_tip]],
      [{ path: "150:-298;450:-298;", style: "TREE=V;LWidth=2;" },
       ["M 85 239 L 85 238 L 385 238 L 385 141"], [docked_tip]],
      [{ path: "150:-299;450:-299;", style: "TREE=V;LWidth=2;" },
       ["M 85 240 L 85 239 L 385 239 L 385 141"], ["85 240 80 230 85 220 90 230"]],
      [{ path: "150:-300;450:-300;", style: "TREE=V;LWidth=2;" },
       ["M 135 240 L 85 240 L 385 240 L 385 141"], ["135 240 125 245 115 240 125 235"]],
      [{ path: "150:-301;450:-301;", style: "TREE=V;LWidth=2;" },
       ["M 135 240 L 85 241 L 385 241 L 385 141"],
       ["135 240 125.1 245.2 115 240.4 124.9 235.2"]]
    ]
    ["0", "1", "3", "2.0", nil].each do |width|
      cases << [{ path: bent, style: width ? "TREE=V;LWidth=#{width};" : "TREE=V;" },
                stale, [stale_tip]]
    end

    cases.each do |input, paths, markers|
      result = render_qea_route(connector_type: "Aggregation", **input)

      expect(result).to eq({ paths: paths, markers: markers }),
                        "route input: #{input.inspect}"
    end
  end

  it "docks width-2 Mode 3 horizontal trees on the facing outlines, keeping the trunk" do
    right = { source: [806, 511, 120, 80], target: [510, 560, 202, 101],
              path: "762:-551;762:-610;", geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=4;",
              style: "Mode=3;TREE=H;LWidth=2;" }
    left = right.merge(source: [510, 560, 202, 101], target: [806, 511, 120, 80],
                       path: "762:-610;762:-551;",
                       geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=2;")
    cases = [
      [right, "Generalization", "M 330 80 L 287 80 L 287 139 L 238 139",
       "238 139 249 133 249 145"],
      [right, "Aggregation", "M 330 80 L 287 80 L 287 139 L 238 139",
       "330 80 320 85 310 80 320 75"],
      [left, "Generalization", "M 238 139 L 287 139 L 287 80 L 330 80",
       "330 80 319 86 319 74"],
      [left, "Aggregation", "M 238 139 L 287 139 L 287 80 L 330 80",
       "238 139 248 134 258 139 248 144"]
    ]

    cases.each do |input, type, path, tip|
      result = render_qea_route(connector_type: type, **input)

      expect(result).to eq({ paths: [path], markers: [tip] }),
                        "#{type} #{input[:geometry]}"
    end
  end

  it "keeps other horizontal tree inputs on their existing routes" do
    base = { source: [806, 511, 120, 80], target: [510, 560, 202, 101],
             path: "762:-551;762:-610;", geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=4;",
             style: "Mode=3;TREE=H;LWidth=2;" }
    cases = [
      ["width 0", { style: "Mode=3;TREE=H;LWidth=0;" },
       { "Generalization" => ["M 331 80 L 287 80 L 287 139 L 35 139", "35 139 46 133 46 145"],
         "Aggregation" => ["M 331 93 L 237 115", "331 93 322.4 100.15 311.53 97.56 320.12 90.41"] }],
      ["width 1", { style: "Mode=3;TREE=H;LWidth=1;" },
       { "Generalization" => ["M 331 80 L 287 80 L 287 139 L 35 139", "35 139 46 133 46 145"],
         "Aggregation" => ["M 331 93 L 237 115", "331 93 322.4 100.15 311.53 97.56 320.12 90.41"] }],
      ["width 3", { style: "Mode=3;TREE=H;LWidth=3;" },
       { "Generalization" => ["M 331 80 L 287 80 L 287 139 L 35 139", "35 139 46 133 46 145"],
         "Aggregation" => ["M 331 93 L 237 115", "331 93 322.4 100.15 311.53 97.56 320.12 90.41"] }],
      ["no width", { style: "Mode=3;TREE=H;" },
       { "Generalization" => ["M 331 80 L 287 80 L 287 139 L 35 139", "35 139 46 133 46 145"],
         "Aggregation" => ["M 331 93 L 237 115", "331 93 322.4 100.15 311.53 97.56 320.12 90.41"] }],
      ["mode 2", { style: "Mode=2;TREE=H;LWidth=2;" },
       { "Generalization" => ["M 331 80 L 287 80 L 287 139 L 35 139", "35 139 46 133 46 145"],
         "Aggregation" => ["M 330 94 L 238 115", "330 94 321.36 101.1 310.5 98.45 319.14 91.35"] }],
      ["tree V", { style: "Mode=3;TREE=V;LWidth=2;" },
       { "Generalization" => ["M 331 80 L 287 80 L 287 139 L 35 139", "35 139 46 133 46 145"],
         "Aggregation" => ["M 330 94 L 238 115", "330 94 321.36 101.1 310.5 98.45 319.14 91.35"] }],
      ["bends differ in x", { path: "762:-551;740:-610;" },
       { "Generalization" => ["M 331 80 L 287 80 L 265 139 L 35 139", "35 139 46 133 46 145"],
         "Aggregation" => ["M 330 94 L 238 115", "330 94 321.36 101.1 310.5 98.45 319.14 91.35"] }],
      ["three bends", { path: "762:-551;762:-580;762:-610;" },
       { "Generalization" => ["M 331 80 L 287 80 L 287 109 L 287 139 L 35 139", "35 139 46 133 46 145"],
         "Aggregation" => ["M 330 94 L 238 115", "330 94 321.36 101.1 310.5 98.45 319.14 91.35"] }],
      ["bend above source", { path: "762:-500;762:-610;" },
       { "Generalization" => ["M 331 80 L 287 29 L 287 139 L 35 139", "35 139 46 133 46 145"],
         "Aggregation" => ["M 330 94 L 238 115", "330 94 321.36 101.1 310.5 98.45 319.14 91.35"] }],
      ["bend below target", { path: "762:-551;762:-670;" },
       { "Generalization" => ["M 331 80 L 287 80 L 287 199 L 35 139", "35 139 47.09 135.71 44.31 147.38"],
         "Aggregation" => ["M 330 94 L 238 115", "330 94 321.36 101.1 310.5 98.45 319.14 91.35"] }],
      ["trunk against target outline", { path: "713:-551;713:-610;" },
       { "Generalization" => ["M 331 80 L 238 80 L 238 139 L 35 139", "35 139 46 133 46 145"],
         "Aggregation" => ["M 330 94 L 238 115", "330 94 321.36 101.1 310.5 98.45 319.14 91.35"] }],
      ["trunk against source outline", { path: "805:-551;805:-610;" },
       { "Generalization" => ["M 331 80 L 330 80 L 330 139 L 35 139", "35 139 46 133 46 145"],
         "Aggregation" => ["M 330 94 L 238 115", "330 94 321.36 101.1 310.5 98.45 319.14 91.35"] }],
      ["overlapping boxes", { target: [700, 560, 202, 101] },
       { "Generalization" => ["M 141 80 L 97 80 L 97 139 L 35 139", "35 139 46 133 46 145"],
         "Aggregation" => ["M 141 80 L 97 80 L 97 139 L 35 139", "141 80 131 85 121 80 131 75"] }]
    ]

    cases.each do |name, override, expected|
      expected.each do |type, (path, tip)|
        result = render_qea_route(connector_type: type, **base.merge(override))

        expect(result).to eq({ paths: [path], markers: [tip] }), "#{name} #{type}"
      end
    end
  end

  it "preserves marker tips and dimensions across adjacent-bend boundaries" do
    [
      [199, ["385 140 379 129 391 129"]],
      [200, []],
      [201, ["385 140 391 151 379 151"]],
      [202, ["385 141 391 152 379 152"]],
      [250, ["385 141 391 152 379 152"]],
      [298, ["385 141 391 152 379 152"]],
      [299, ["385 141 391 152 379 152"]],
      [300, ["385 141 391 152 379 152"]]
    ].each do |bend, expected|
      result = render_qea_route(path: "150:-#{bend};450:-#{bend};", style: "TREE=V;LWidth=2;")

      expect(result[:markers]).to eq(expected), "bend: #{bend}"
    end
  end
end
