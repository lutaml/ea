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

  # Records of the pinned 220 corpus (20251010_current_plateau_v5.1.qea):
  # t_diagramlinks 142/558, 177/558 and 176/787, Mode=3;LWidth=2 with no TREE.
  let(:custom_trunk) do
    { source: [632, 1038, 216, 241], target: [622, 23, 235, 176],
      path: "794:-919;740:-919;", geometry: "SX=54;SY=-1;EX=2;EY=-88;EDGE=1;",
      style: "Mode=3;LWidth=2;" }
  end

  it "preserves a valid stored horizontal trunk of width-2 Mode 3 custom Aggregations" do
    trunk = "M 207 1054 L 207 936 L 153 936 L 153 217"
    records = [
      [custom_trunk, trunk, "207 1054 202 1044 207 1034 212 1044"],
      [custom_trunk.merge(source: [585, 1027, 216, 241], target: [575, 12, 235, 176],
                          path: "747:-908;693:-908;"),
       trunk, "207 1054 202 1044 207 1034 212 1044"],
      [{ source: [529, 783, 216, 241], target: [572, 39, 235, 159],
         path: "637:-249;689:-249;", geometry: "SX=0;SY=-4;EX=0;EY=0;EDGE=1;",
         style: "Mode=3;LWidth=2;" },
       "M 143 783 L 143 250 L 195 250 L 195 200", "143 783 138 773 143 763 148 773"]
    ]

    records.each do |input, path, tip|
      result = render_qea_route(connector_type: "Aggregation", **input)

      expect(result).to eq({ paths: [path], markers: [tip] }),
                        "route input: #{input.inspect}"
    end
  end

  it "keeps other custom-line inputs on their existing routes" do
    cases = [
      ["mode 2", { style: "Mode=2;LWidth=2;" },
       ["M 201 1054 L 162 217"], ["201 1054 195.54 1044.24 200.07 1034.02 205.53 1043.78"]],
      ["no mode", { style: "LWidth=2;" },
       ["M 201 1054 L 162 217"], ["201 1054 195.54 1044.24 200.07 1034.02 205.53 1043.78"]],
      ["width 1", { style: "Mode=3;LWidth=1;" },
       ["M 201 1055 L 162 216"], ["201 1055 195.54 1045.24 200.07 1035.02 205.53 1044.78"]],
      ["width 3", { style: "Mode=3;LWidth=3;" },
       ["M 201 1055 L 162 216"], ["201 1055 195.54 1045.24 200.07 1035.02 205.53 1044.78"]],
      ["no width", { style: "Mode=3;" },
       ["M 201 1055 L 162 216"], ["201 1055 195.54 1045.24 200.07 1035.02 205.53 1044.78"]],
      ["tree H", { style: "Mode=3;TREE=H;LWidth=2;" },
       ["M 201 1054 L 162 217"], ["201 1054 195.54 1044.24 200.07 1034.02 205.53 1043.78"]],
      ["tree V", { style: "Mode=3;TREE=V;LWidth=2;" },
       ["M 207 1054 L 207 936 L 153 936 L 153 217"], ["207 1054 202 1044 207 1034 212 1044"]],
      ["association", { connector_type: "Association" },
       ["M 201 1055 L 162 216", "M 168.69 230.71 L 162 216 L 156.7 231.26"], []],
      ["generalization", { connector_type: "Generalization" },
       ["M 207 1054 L 207 936 L 153 936 L 153 217"], ["153 217 159 228 147 228"]],
      ["bend left of source", { path: "600:-919;740:-919;" },
       ["M 201 1054 L 162 217"], ["201 1054 195.54 1044.24 200.07 1034.02 205.53 1043.78"]],
      ["bend right of target", { path: "794:-919;900:-919;" },
       ["M 201 1054 L 162 217"], ["201 1054 195.54 1044.24 200.07 1034.02 205.53 1043.78"]],
      ["bends differ in y", { path: "794:-919;740:-900;" },
       ["M 201 1054 L 162 217"], ["201 1054 195.54 1044.24 200.07 1034.02 205.53 1043.78"]],
      ["bends share x", { path: "794:-919;794:-900;" },
       ["M 201 1054 L 162 217"], ["201 1054 195.54 1044.24 200.07 1034.02 205.53 1043.78"]],
      ["three bends", { path: "794:-919;770:-919;740:-919;" },
       ["M 201 1054 L 162 217"], ["201 1054 195.54 1044.24 200.07 1034.02 205.53 1043.78"]],
      ["trunk at target outline", { path: "794:-200;740:-200;" },
       ["M 201 1054 L 162 217"], ["201 1054 195.54 1044.24 200.07 1034.02 205.53 1043.78"]],
      ["trunk at source outline", { path: "794:-1037;740:-1037;" },
       ["M 201 1054 L 162 217"], ["201 1054 195.54 1044.24 200.07 1034.02 205.53 1043.78"]]
    ]

    cases.each do |name, override, paths, markers|
      input = custom_trunk.merge(override)
      result = render_qea_route(**{ connector_type: "Aggregation" }.merge(input))

      expect(result).to eq({ paths: paths, markers: markers }), name
    end
  end

  let(:flush_trunk) do
    { source: [443, 240, 184, 70], target: [378, 49, 179, 70],
      path: "534:-169;467:-169;", geometry: "SX=0;SY=0;EDGE=1;",
      style: "Mode=3;LWidth=0;TREE=V;" }
  end

  it "docks width-0 vertical tree Aggregations on the box edges, keeping the trunk" do
    # Records: t_diagramlinks 199/742 (plateau) and 20/59 (basic.qea).
    records = [
      [flush_trunk, "M 191 231 L 191 160 L 124 160 L 124 110", "191 231 186 221 191 211 196 221"],
      [{ source: [382, 209, 110, 70], target: [287, 30, 110, 70],
         path: "437:-150;342:-150;", geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=1;",
         style: "Mode=3;LWidth=0;TREE=V;" },
       "M 185 219 L 185 160 L 90 160 L 90 110", "185 219 180 209 185 199 190 209"]
    ]

    records.each do |input, path, tip|
      result = render_qea_route(connector_type: "Aggregation", **input)

      expect(result).to eq({ paths: [path], markers: [tip] }),
                        "route input: #{input.inspect}"
    end
  end

  it "keeps other width-0 tree inputs on their existing routes" do
    flattened = [["M 179 231 L 136 110"], ["179 231 170.94 223.25 172.3 212.15 180.36 219.9"]]
    cases = [
      ["mode 2", { style: "Mode=2;LWidth=0;TREE=V;" }, *flattened],
      ["no mode", { style: "LWidth=0;TREE=V;" }, *flattened],
      ["width 1", { style: "Mode=3;LWidth=1;TREE=V;" }, *flattened],
      ["width 3", { style: "Mode=3;LWidth=3;TREE=V;" }, *flattened],
      ["no width", { style: "Mode=3;TREE=V;" }, *flattened],
      ["tree H", { style: "Mode=3;LWidth=0;TREE=H;" }, *flattened],
      ["no tree", { style: "Mode=3;LWidth=0;" }, *flattened],
      ["width 2", { style: "Mode=3;LWidth=2;TREE=V;" },
       ["M 191 230 L 191 160 L 124 160 L 124 111"], ["191 230 186 220 191 210 196 220"]],
      ["association", { connector_type: "Association" },
       ["M 179 231 L 136 110", "M 146.68 122.12 L 136 110 L 135.37 126.14"], []],
      ["generalization", { connector_type: "Generalization" },
       ["M 191 231 L 191 160 L 124 160 L 124 110"], ["124 110 130 121 118 121"]],
      ["bend left of source", { path: "420:-169;467:-169;" }, *flattened],
      ["bend right of target", { path: "534:-169;600:-169;" }, *flattened],
      ["bends differ in y", { path: "534:-169;467:-160;" }, *flattened],
      ["bends share x", { path: "534:-169;534:-160;" }, *flattened],
      ["three bends", { path: "534:-169;500:-169;467:-169;" }, *flattened],
      ["trunk at target edge", { path: "534:-119;467:-119;" }, *flattened],
      ["trunk at source edge", { path: "534:-240;467:-240;" }, *flattened]
    ]

    cases.each do |name, override, paths, markers|
      input = flush_trunk.merge(override)
      result = render_qea_route(**{ connector_type: "Aggregation" }.merge(input))

      expect(result).to eq({ paths: paths, markers: markers }), name
    end
  end

  let(:computed_jog) do
    { source: [961, 736, 204, 72], target: [1250, 352, 312, 465], path: nil,
      geometry: "SX=103;SY=-8;EX=-156;EY=-196;EDGE=2;", style: "Mode=3;LWidth=2;" }
  end

  it "collapses a one-pixel computed jog between facing horizontal ports" do
    # t_diagramlinks 98/1644 of the pinned 220: ports differ by one pixel in y
    # and EA draws one horizontal line clipped at the outer outlines.
    result = render_qea_route(connector_type: "Generalization", **computed_jog)

    expect(result).to eq(paths: ["M 240 468 L 323 468"], markers: ["323 468 312 474 312 462"])
  end

  let(:computed_zero_leg) do
    { source: [300, 70, 168, 80], target: [570, 20, 343, 465], path: nil,
      geometry: "SX=84;SY=-1;EX=-171;EY=141;EDGE=2;", style: "Mode=3;LWidth=2;" }
  end

  it "collapses a zero-length computed terminal leg between facing horizontal ports" do
    # t_diagramlinks 50/333: [source, target, target] duplicates the end point,
    # which stops the outline clipping; the reference is one 2-point line.
    result = render_qea_route(connector_type: "Generalization", **computed_zero_leg)

    expect(result).to eq(paths: ["M 204 131 L 304 131"], markers: ["304 131 293 137 293 125"])
  end

  it "keeps other zero-leg inputs unchanged" do
    duplicated = ["M 203 131 L 305 131 L 305 131"]
    cases = [
      ["stored duplicate path", { path: "570:-111;570:-111;" },
       ["M 204 131 L 305 131 L 305 131 L 305 131"], []],
      ["mode 2", { style: "Mode=2;LWidth=2;" }, duplicated, []],
      ["width 0", { style: "Mode=3;LWidth=0;" }, duplicated, []],
      ["tree V", { style: "Mode=3;LWidth=2;TREE=V;" }, duplicated, []]
    ]

    cases.each do |name, override, paths, markers|
      input = computed_zero_leg.merge(override)
      result = render_qea_route(**{ connector_type: "Generalization" }.merge(input))

      expect(result).to eq({ paths: paths, markers: markers }), name
    end
  end

  it "keeps other computed and stored routes unchanged" do
    jogged = ["M 239 468 L 324 468 L 324 469"]
    jog_tip = ["324 469 318 458 330 458"]
    cases = [
      ["stored 1px jog", { path: "1250:-780;1250:-781;" },
       ["M 240 468 L 324 468 L 324 469 L 324 469"], []],
      ["mode 2", { style: "Mode=2;LWidth=2;" }, jogged, jog_tip],
      ["width 0", { style: "Mode=3;LWidth=0;" }, jogged, jog_tip],
      ["tree V", { style: "Mode=3;LWidth=2;TREE=V;" }, jogged, jog_tip],
      ["tree H", { style: "Mode=3;LWidth=2;TREE=H;" }, jogged, jog_tip],
      ["overlapping boxes", { target: [1100, 352, 312, 465] },
       ["M 239 468 L 174 468 L 174 469"], ["174 469 168 458 180 458"]],
      ["vertical ports", { geometry: "SX=0;SY=-8;EX=0;EY=-196;EDGE=1;" },
       ["M 163 423 L 323 248"], ["323 248 320.01 260.17 311.15 252.07"]]
    ]

    cases.each do |name, override, paths, markers|
      input = computed_jog.merge(override)
      result = render_qea_route(**{ connector_type: "Generalization" }.merge(input))

      expect(result).to eq({ paths: paths, markers: markers }), name
    end
  end

  it "keeps a computed jog when the source height is outside the target span" do
    result = render_qea_route(
      source: [100, 100, 100, 100], target: [300, 150, 100, 100],
      path: "", style: "Mode=3;LWidth=2;",
      geometry: "SX=50;SY=1;EX=-50;EY=50;EDGE=2;"
    )

    expect(result[:paths]).to eq(["M 135 89 L 235 89 L 235 90"])
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

  let(:lateral_corner) do
    { connector_type: "Aggregation", source: [181, 460, 220, 100],
      target: [510, 560, 202, 101], path: "291:-610;",
      geometry: "SX=2;SY=41;EX=0;EY=0;EDGE=3;",
      style: "Mode=3;TREE=LH;LWidth=2;" }
  end

  it "retains stored lateral corners and docks each leg on its own box" do # rubocop:disable Metrics/BlockLength
    cases = [
      [lateral_corner, "M 145 140 L 145 190 L 364 190",
       ["145 140 150 150 145 160 140 150"]],
      [lateral_corner.merge(source: [1121, 1514, 197, 80],
                            target: [741, 963, 396, 261], path: "1219:-1093;",
                            geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=1;"),
       "M 513 591 L 513 170 L 431 170", ["513 591 508 581 513 571 518 581"]],
      [{ connector_type: "Aggregation", source: [291, 486, 110, 70],
         target: [206, 208, 110, 70], path: "261:-521;",
         geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=4;", style: "Mode=3;TREE=LV;LWidth=0;" },
       "M 120 353 L 90 353 L 90 110", ["120 353 110 358 100 353 110 348"]],
      [{ connector_type: "Association", source: [1303, 883, 268, 88],
         target: [1073, 1014, 167, 80], path: "1437:-1054;",
         geometry: "SX=37;SY=0;EX=0;EY=0;EDGE=3;", style: "Mode=3;TREE=LH;LWidth=2;" },
       "M 399 128 L 399 211 L 202 211", []]
    ]
    cases.each do |input, path, markers|
      rendered = render_qea_route(**input)

      expect(rendered[:paths].first).to eq(path), input.inspect
      expect(rendered[:markers]).to eq(markers), input.inspect
    end
  end

  it "preserves other modes, styles, types and invalid lateral corners" do # rubocop:disable Metrics/BlockLength
    path = "M 200 141 L 363 171"
    markers = ["200 141 210.74 137.89 219.67 144.62 208.93 147.73"]
    controls = [
      { style: "Mode=1;TREE=LH;LWidth=2;" },
      { style: "Mode=2;TREE=LH;LWidth=2;" },
      { style: "TREE=LH;LWidth=2;" },
      { path: "291:-610;300:-610;" }, { path: "291:-500;" },
      { path: "180:-610;" }, { path: "291:-662;" },
      { path: "600:-610;" }, { path: "" }, { path: "291:-610;garbage" },
      { style: "Mode=3;TREE=H;LWidth=2;" }
    ]
    controls.each do |override|
      expect(render_qea_route(**lateral_corner.merge(override)))
        .to eq(paths: [path], markers: markers), override.inspect
    end
    ["Mode=3;TREE=LH;LWidth=1;", "Mode=3;TREE=LH;"].each do |style|
      expect(render_qea_route(**lateral_corner.merge(style: style)))
        .to eq(paths: ["M 195 140 L 364 171"],
               markers: ["195 140 205.74 136.89 214.67 143.61 203.93 146.72"])
    end
    expect(render_qea_route(**lateral_corner.merge(connector_type: "Generalization")))
      .to eq(paths: ["M 147 40 L 145 190 L 364 190"],
             markers: ["364 190 353 196 353 184"])
  end

  it "docks an untyped Mode 3 Association corner on the outline of each leg's box" do
    association = lateral_corner.merge(connector_type: "Association", style: "Mode=3;LWidth=2;",
                                       geometry: "SX=2;SY=41;EX=3;EY=-20;EDGE=3;")
    cases = [
      [association, "M 145 141 L 145 190 L 363 190"],
      [association.merge(style: "Mode=3;LWidth=0;"), "M 145 140 L 145 190 L 364 190"],
      [association.merge(source: [1121, 1514, 197, 80], target: [741, 963, 396, 261],
                         path: "1219:-1093;"), "M 513 590 L 513 170 L 432 170"]
    ]
    cases.each do |input, path|
      expect(render_qea_route(**input)[:paths].first).to eq(path), input.inspect
    end
  end

  it "keeps an untyped Association corner without stored port offsets on its authored route" do
    zero = lateral_corner.merge(connector_type: "Association", style: "Mode=3;LWidth=2;",
                                geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=3;")
    one_end = zero.merge(geometry: "SX=2;SY=41;EX=0;EY=0;EDGE=3;")
    expect([zero, one_end].map { |input| render_qea_route(**input)[:paths].first })
      .to eq(["M 255 124 L 364 158", "M 195 140 L 364 171"])
  end

  it "keeps an untyped Aggregation corner when it fits both boxes" do
    expect(render_qea_route(**lateral_corner.merge(style: "Mode=3;LWidth=2;")))
      .to eq(paths: ["M 145 141 L 145 190 L 363 190"],
             markers: ["145 141 150 151 145 161 140 151"])
  end

  let(:offset_line) do
    { connector_type: "Association", source: [546, 91, 180, 80],
      target: [79, 33, 312, 465], path: "",
      geometry: "SX=-89;SY=-6;EX=43;EY=129;EDGE=4;", style: "Mode=3;LWidth=2;" }
  end

  it "joins an empty-Path Association's stored ray origins and clips at each outline" do
    cases = [
      [offset_line, "M 501 143 L 348 143"],
      [offset_line.merge(style: "Mode=3;LWidth=0;"), "M 502 143 L 347 143"],
      [offset_line.merge(geometry: "SX=-89;SY=-6;EX=43;EY=130;EDGE=2;"), "M 501 143 L 348 142"],
      [offset_line.merge(geometry: "SX=-89;SY=-6;EX=43;EY=130;EDGE=2;", style: "Mode=3;LWidth=0;"),
       "M 502 143 L 347 142"]
    ]
    cases.each do |input, path|
      expect(render_qea_route(**input)[:paths].first).to eq(path), input.inspect
    end
  end

  it "accepts a width-2 stored origin on its own box's 1px outer stroke only" do
    outline = offset_line.merge(geometry: "SX=-89;SY=-6;EX=157;EY=128;EDGE=4;")
    cases = [
      outline, outline.merge(style: "Mode=3;LWidth=0;"),
      outline.merge(geometry: "SX=-89;SY=-6;EX=158;EY=128;EDGE=4;"),
      outline.merge(geometry: "SX=-89;SY=-6;EX=157;EY=129;EDGE=4;")
    ]
    expect(cases.map { |input| render_qea_route(**input)[:paths].first })
      .to eq(["M 501 144 L 348 144", "M 502 146 L 348 400",
              "M 502 146 L 349 400", "M 501 143 L 348 143"])
  end

  it "marks only produced stored Association rays for the emitter" do
    flags = [offset_line, offset_line.merge(connector_type: "Aggregation"),
             offset_line.merge(style: "Mode=3;LWidth=1;"),
             offset_line.merge(path: "300:-120;")].map do |input|
      connector = nil
      render_qea_route(**input) { |document| connector = document.diagrams.first.connectors.first }
      connector.style[:stored_association_ray]
    end

    expect(flags).to eq([true, nil, nil, nil])
  end

  let(:border_ray) do
    { connector_type: "Association", source: [301, 528, 100, 77],
      target: [295, 394, 136, 77], path: "",
      geometry: "SX=2;SY=38;EX=-11;EY=-39;EDGE=1;", style: "Mode=3;LWidth=2;" }
  end

  it "docks a width-2 stored ray with both origins on their borders on the outer stroke" do
    expect(render_qea_route(**border_ray)[:paths].first).to eq("M 92 173 L 92 118")
  end

  it "keeps width-0 border origins and unmarked diagonals on their existing route" do
    controls = [
      border_ray.merge(style: "Mode=3;LWidth=0;"),
      border_ray.merge(path: "300:-120;"),
      border_ray.merge(geometry: "EDGE=1;"),
      border_ray.merge(style: "Mode=2;LWidth=2;")
    ]
    expected = ["M 92 174 L 92 40", "M 93 174 L 40 -234 L 92 117",
                "M 94 174 L 99 117", "M 92 174 L 92 40"]
    expect(controls.map { |input| render_qea_route(**input)[:paths].first }).to eq(expected)
  end

  it "uses the target center when its stored offsets are zero" do
    input = offset_line.merge(geometry: "SX=-89;SY=-6;EX=0;EY=0;EDGE=4;")
    expect(render_qea_route(**input)[:paths].first).to eq("M 501 144 L 348 207")
  end

  it "seats nonuniform Mode 2 offsets on the source row" do
    input = offset_line.merge(style: "Mode=2;LWidth=2;")
    expect(render_qea_route(**input)[:paths].first).to eq("M 501 144 L 348 144")
  end

  it "keeps other types, styles and unusable origins on their existing route" do
    controls = [
      offset_line.merge(connector_type: "Aggregation"),
      offset_line.merge(style: "Mode=3;LWidth=1;"),
      offset_line.merge(style: "Mode=3;TREE=V;LWidth=2;"),
      offset_line.merge(path: "300:-120;"),
      offset_line.merge(geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=4;"),
      offset_line.merge(geometry: "SX=-89;SY=-6;EX=43;EY=300;EDGE=4;")
    ]
    expected = ["M 501 143 L 348 143", "M 502 146 L 347 288",
                "M 502 146 L 347 288", "M 502 146 L 347 288", "M 502 168 L 347 219",
                "M 502 146 L 274 505"]
    expect(controls.map { |input| render_qea_route(**input)[:paths].first }).to eq(expected)
  end

  let(:square_corner) do
    { connector_type: "Association", source: [800, 515, 100, 162],
      target: [540, 740, 100, 80], path: "621:-627;",
      geometry: "SX=0;SY=0;EX=0;EY=0;EDGE=4;", style: "Mode=3;TREE=OS;LWidth=2;" }
  end

  it "retains square-routing bends and projects endpoints onto their own edges" do # rubocop:disable Metrics/BlockLength
    cases = [
      [square_corner, "M 295 152 L 116 152 L 116 265", []],
      [square_corner.merge(path: "621:-627;621:-627;"),
       "M 295 152 L 116 152 L 116 152 L 116 265", []],
      [square_corner.merge(source: [701, 380, 100, 80], target: [306, 231, 203, 125],
                           path: "663:-404;663:-265;"),
       "M 430 213 L 392 213 L 392 74 L 238 74", []],
      [square_corner.merge(connector_type: "Generalization", source: [311, 1135, 120, 80],
                           target: [611, 64, 330, 122], path: "161:-1167;161:-123;"),
       "M 35 1143 L -115 1143 L -115 99 L 335 99", ["335 99 324 105 324 93"]],
      [square_corner.merge(connector_type: "Aggregation", source: [1290, 1200, 220, 104],
                           target: [945, 569, 365, 240], path: "1394:-646;"),
       "M 484 671 L 484 117 L 400 117", ["484 671 479 661 484 651 489 661"]],
      [square_corner.merge(source: [710, 820, 127, 110], target: [400, 591, 203, 121],
                           path: "748:-956;291:-956;291:-683;400:-683;"),
       "M 383 379 L 383 405 L -74 405 L -74 132 L 35 132", []]
    ]
    cases.each do |input, path, markers|
      rendered = render_qea_route(**input)

      expect(rendered[:paths].first).to eq(path), input.inspect
      expect(rendered[:markers]).to eq(markers), input.inspect
    end
  end

  it "preserves custom diagonals, invalid corners and other square-routing styles" do # rubocop:disable Metrics/BlockLength
    ["Mode=2;TREE=OS;LWidth=2;", "TREE=OS;LWidth=2;", "Mode=3;LWidth=2;",
     "Mode=3;TREE=OS;LWidth=0;", "Mode=3;TREE=OR;LWidth=2;"].each do |style|
      expect(render_qea_route(**square_corner.merge(style: style))[:paths].first)
        .to eq("M 295 121 L 116 152 L 35 305"), style
    end
    {
      "621:-627;620:-650;" => "M 295 121 L 116 152 L 115 175 L 35 305",
      "850:-600;" => "M 295 121 L 345 125 L 35 305",
      "400:-100;" => "M 295 121 L -105 -375 L 35 305",
      "621:-627;garbage" => "M 295 121 L 116 152 L 35 305",
      "" => "M 295 156 L 135 269"
    }.each do |path, expected|
      expect(render_qea_route(**square_corner.merge(path: path))[:paths].first)
        .to eq(expected), path
    end
    expect(render_qea_route(**square_corner.merge(style: "Mode=1;TREE=OS;LWidth=2;"))[:paths].first)
      .to eq("M 295 156 L 135 269")
  end

  let(:derived_lateral) do
    { connector_type: "Association", source: [141, 689, 100, 80], target: [370, 676, 269, 200],
      path: "", geometry: "EDGE=4;SX=49;SY=17;EX=0;EY=0;", style: "Mode=3;TREE=LH;LWidth=2;" }
  end
  let(:level_lateral) do
    { connector_type: "Generalization", source: [22, 210, 196, 80], target: [330, 10, 287, 465],
      path: "", geometry: "SX=0;SY=0;EX=-11;EY=3;EDGE=2;", style: "Mode=3;TREE=LH;LWidth=2;" }
  end

  it "derives the lateral corner from the source center x and target center y without a stored corner" do
    {
      "empty Path" => [derived_lateral, "M 85 133 L 85 140 L 264 140"],
      "rejected stored corner" => [derived_lateral.merge(path: "928:-725;"), "M 85 133 L 85 140 L 264 140"],
      "level Generalization" => [level_lateral, "M 231 272 L 343 272"],
      "level width-0 Association" => [level_lateral.merge(connector_type: "Association",
                                                          style: "Mode=3;TREE=LH;LWidth=0;"),
                                      "M 231 272 L 343 272"]
    }.each do |name, (input, path)|
      expect(render_qea_route(**input)[:paths].first).to eq(path), name
    end
  end

  it "keeps other lateral inputs on their existing routes" do
    {
      "Aggregation" => [derived_lateral.merge(connector_type: "Aggregation"), "M 136 110 L 263 124"],
      "Generalization corner" => [level_lateral.merge(path: "500:-100;"), "M 231 130 L 513 130 L 513 40"],
      "LV" => [derived_lateral.merge(style: "Mode=3;TREE=LV;LWidth=2;"), "M 135 110 L 264 124"],
      "Mode 2" => [derived_lateral.merge(style: "Mode=2;TREE=LH;LWidth=2;"), "M 135 110 L 264 124"],
      "source center inside target span" => [derived_lateral.merge(target: [170, 676, 269, 200]),
                                             "M 135 110 L 64 77"]
    }.each do |name, (input, path)|
      expect(render_qea_route(**input)[:paths].first).to eq(path), name
    end
  end

  let(:stored_ray) do
    { connector_type: "Aggregation", source: [982, 532, 219, 88],
      target: [600, 520, 212, 125], path: nil,
      geometry: "EDGE=4;SX=0;SY=24;EX=0;EY=30;", style: "Mode=3;LWidth=2;" }
  end

  it "mirrors stored mathematical Y offsets for direct ray origins" do # rubocop:disable Metrics/BlockLength
    cases = [
      [stored_ray, "M 416 72 L 248 72", [416, 72]],
      [stored_ray.merge(connector_type: "Generalization", source: [781, 64, 202, 101],
                        target: [327, 8, 387, 193],
                        geometry: "SX=-81;SY=-17;EX=-4;EY=-26;EDGE=4;"),
       "M 488 162 L 423 162", [423, 162]],
      [stored_ray.merge(connector_type: "Generalization", source: [489, 741, 357, 98],
                        target: [510, 621, 336, 88], path: "709:-432;645:-432;",
                        geometry: "SX=0;SY=49;EX=-8;EY=6;EDGE=1;", style: "Mode=1;LWidth=2;"),
       "M 213 159 L 214 129", [214, 129]]
    ]
    cases.each do |input, path, tip|
      rendered = render_qea_route(**input)

      expect(rendered[:paths]).to eq([path]), input.inspect
      expect(rendered[:markers].size).to eq(1)
      expect(rendered[:markers].first.split.map(&:to_f).take(2)).to eq(tip)
    end
  end

  it "preserves stored ports and waypoints while correcting ray origins" do
    connector = nil
    render_qea_route(**stored_ray) do |document|
      connector = document.diagrams.first.connectors.first
    end

    expect([connector.source_anchor.x, connector.source_anchor.y]).to eq([1091, 552])
    expect([connector.target_anchor.x, connector.target_anchor.y]).to eq([706, 552])
    expect([connector.source_port.x, connector.source_port.y]).to eq([1092, 532])
    expect([connector.target_port.x, connector.target_port.y]).to eq([706, 520])
    expect(connector.waypoints.map { |point| [point.position.x, point.position.y] })
      .to eq([[982, 532], [812, 532]])
  end

  it "preserves computed ports while restoring a level stored ray" do
    connector = nil
    result = render_qea_route(connector_type: "Generalization", **computed_jog) do |document|
      connector = document.diagrams.first.connectors.first
    end

    expect(result[:paths]).to eq(["M 240 468 L 323 468"])
    expect([connector.source_anchor.x, connector.source_anchor.y]).to eq([1166, 780])
    expect([connector.target_anchor.x, connector.target_anchor.y]).to eq([1250, 780])
    expect([connector.source_port.x, connector.source_port.y]).to eq([1165, 780])
    expect([connector.target_port.x, connector.target_port.y]).to eq([1250, 780])
  end

  it "keeps custom paths, other modes, tree styles and missing ports on their original origins" do # rubocop:disable Metrics/BlockLength
    controls = [
      { style: "Mode=2;LWidth=2;" }, { style: "LWidth=2;" },
      { style: "Mode=3;TREE=V;LWidth=2;" },
      { path: "1000:-700;" }, { path: "1000:-700;1100:-700;" }
    ]
    controls.each do |override|
      connector = nil
      render_qea_route(**stored_ray.merge(override)) do |document|
        connector = document.diagrams.first.connectors.first
      end

      expect([connector.source_anchor.x, connector.source_anchor.y]).to eq([1091, 600]), override.inspect
      expect([connector.target_anchor.x, connector.target_anchor.y]).to eq([706, 612]), override.inspect
    end
    connector = nil
    render_qea_route(**stored_ray.merge(geometry: "EDGE=4;SX=0;SY=24;")) do |document|
      connector = document.diagrams.first.connectors.first
    end
    expect([connector.source_anchor.x, connector.source_anchor.y]).to eq([1091, 600])
    expect([connector.target_anchor.x, connector.target_anchor.y]).to eq([706, 582])
    expect(connector.target_port).to be_nil
  end

  it "keeps ray origins when the boxes overlap" do
    connector = nil
    render_qea_route(**stored_ray.merge(target: [1000, 532, 212, 125])) do |document|
      connector = document.diagrams.first.connectors.first
    end

    expect([connector.source_anchor.x, connector.source_anchor.y]).to eq([1091, 600])
    expect([connector.target_anchor.x, connector.target_anchor.y]).to eq([1106, 624])
  end

  it "keeps origins when the stored edge faces away from the other box" do
    connector = nil
    render_qea_route(**stored_ray.merge(source: [600, 520, 212, 125],
                                        target: [982, 532, 219, 88])) do |document|
      connector = document.diagrams.first.connectors.first
    end
    expect([connector.source_anchor.x, connector.source_anchor.y]).to eq([706, 606])
    expect([connector.target_anchor.x, connector.target_anchor.y]).to eq([1091, 606])

    render_qea_route(**stored_ray.merge(source: [100, 100, 100, 80],
                                        target: [100, 300, 100, 80],
                                        geometry: "EDGE=1;SX=1;SY=20;EX=1;EY=20;")) do |document|
      connector = document.diagrams.first.connectors.first
    end
    expect([connector.source_anchor.x, connector.source_anchor.y]).to eq([151, 160])
    expect([connector.target_anchor.x, connector.target_anchor.y]).to eq([151, 360])
  end

  let(:empty_path_ray) do
    { connector_type: "Aggregation", source: [857, 561, 219, 88],
      target: [1250, 352, 312, 465], path: nil, style: "Mode=3;LWidth=2;",
      geometry: "EDGE=2;EX=-156;EY=-9;SX=39;SY=12;" }
  end

  it "uses direct mathematical rays when an EDGE2 connector has no authored bends" do # rubocop:disable Metrics/BlockLength
    cases = [
      [empty_path_ray, "M 255 281 L 427 281"],
      [empty_path_ray.merge(connector_type: "Generalization", source: [137, 95, 326, 1060],
                            target: [554, 264, 312, 465],
                            geometry: "EDGE=2;SX=159;SY=111;EX=-156;EY=-18;"),
       "M 362 459 L 451 459"],
      [empty_path_ray.merge(source: [134, 387, 219, 88], target: [510, 35, 312, 465],
                            geometry: "EDGE=2;SX=109;SY=2;EX=-156;EY=-162;"),
       "M 255 434 L 410 434"],
      [empty_path_ray.merge(source: [560, 210, 110, 80], target: [880, 210, 170, 80],
                            geometry: "EDGE=2;SX=6;SY=0;EX=1;EY=0;"),
       "M 146 80 L 354 80"]
    ]
    cases.each do |input, path|
      connector = nil
      rendered = render_qea_route(**input) do |document|
        connector = document.diagrams.first.connectors.first
      end

      expect(rendered[:paths]).to eq([path]), input.inspect
      expect(connector.waypoints.size).to eq(2)
      expect(rendered[:markers].size).to eq(1)
    end
  end

  it "renders zero-length and sloped computed legs as direct rays" do
    cases = [
      [computed_zero_leg.merge(connector_type: "Aggregation"),
       "M 204 131 L 304 131", "204 131 214 126 224 131 214 136"],
      [computed_zero_leg.merge(geometry: "SX=84;SY=-1;EX=-171;EY=138;EDGE=2;"),
       "M 204 131 L 304 133", "304 133 292.88 138.78 293.12 126.78"],
      [computed_jog.merge(connector_type: "Aggregation"),
       "M 240 468 L 323 468", "240 468 250 463 260 468 250 473"],
      [computed_jog.merge(geometry: "SX=103;SY=-8;EX=-156;EY=-193;EDGE=2;"),
       "M 240 468 L 323 465", "323 465 312.22 471.39 311.79 459.4"]
    ]
    cases.each do |input, path, marker|
      expect(render_qea_route(**input)).to eq(paths: [path], markers: [marker])
    end
  end

  it "preserves explicit derived ports while removing the unauthored corner" do
    connector = nil
    render_qea_route(**empty_path_ray) do |document|
      connector = document.diagrams.first.connectors.first
    end

    expect([connector.source_port.x, connector.source_port.y]).to eq([1076, 571])
    expect([connector.target_port.x, connector.target_port.y]).to eq([1250, 594])
    expect(connector.waypoints.map { |point| [point.position.x, point.position.y] })
      .to eq([[1076, 571], [1250, 594]])
    expect([connector.source_anchor.x, connector.source_anchor.y]).to eq([1005, 593])
    expect([connector.target_anchor.x, connector.target_anchor.y]).to eq([1250, 593])
  end

  it "preserves the computed route when EDGE2 faces away from the target" do
    connector = nil
    render_qea_route(**empty_path_ray.merge(source: [1250, 352, 312, 465],
                                            target: [857, 561, 219, 88])) do |document|
      connector = document.diagrams.first.connectors.first
    end

    expect(connector.waypoints.size).to eq(3)
    expect([connector.source_anchor.x, connector.source_anchor.y]).to eq([1445, 596])
    expect([connector.target_anchor.x, connector.target_anchor.y]).to eq([810, 596])
  end

  it "restores the target diamond when a generated terminal leg was empty" do
    result = render_qea_route(
      connector_type: "Aggregation", source: [560, 210, 110, 80],
      target: [880, 210, 170, 80], path: nil, style: "Mode=3;LWidth=2;",
      geometry: "EDGE=2;SX=6;SY=0;EX=1;EY=0;"
    ) do |document|
      association = document.relationships.first
      association.source_aggregation = "none"
      association.target_aggregation = "composite"
    end

    expect(result[:paths]).to eq(["M 146 80 L 354 80", "M 339 86 L 354 80 L 339 74"])
    expect(result[:markers]).to eq(["354 80 344 85 334 80 344 75"])
  end
end
