# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::Labels do
  let(:source_property) do
    Ea::Model::Property.new(
      id: "p_src",
      name: "items",
      owner_id: "c1",
      visibility: "public",
      multiplicity_lower: 0,
      multiplicity_upper: -1
    )
  end
  let(:target_property) do
    Ea::Model::Property.new(
      id: "p_tgt",
      name: "owner",
      owner_id: "c2",
      visibility: "public",
      multiplicity_lower: 0,
      multiplicity_upper: 1
    )
  end
  let(:classifier_a) do
    Ea::Model::Klass.new(id: "c1", name: "A", properties: [source_property])
  end
  let(:classifier_b) do
    Ea::Model::Klass.new(id: "c2", name: "B", properties: [target_property])
  end
  let(:relationship) do
    Ea::Model::Association.new(
      id: "r1",
      source_id: "p_src",
      target_id: "p_tgt"
    )
  end
  let(:connector) do
    Ea::Model::DiagramConnector.new(
      id: "dc1",
      relationship_ref: relationship.id,
      waypoints: [
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 0, y: 0)),
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 100, y: 0))
      ],
      label_boxes: {
        llb: { "ox" => 0, "oy" => 30 },
        llt: { "ox" => 10, "oy" => 15 }
      }
    )
  end
  let(:document) do
    Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      classifiers: [classifier_a, classifier_b],
      relationships: [relationship],
      diagrams: [Ea::Model::Diagram.new(id: "d1", name: "D", connectors: [connector])]
    )
  end
  let(:diagram) { document.diagrams.first }
  let(:renderer) { described_class.new(diagram, model_index: document.index_by_id) }

  it "emits role name text for the source-end label" do
    out = renderer.render
    expect(out).to include("+items")
  end

  it "emits multiplicity text" do
    out = renderer.render
    expect(out).to include("0..*")
  end

  it "uses the configured label family for connector text" do
    theme = Ea::Theme::Definition.new(id: "labels", font_family: "Carlito",
                                      label_font_family: "Cambria", font_size: 7)
    labels = described_class.new(diagram, model_index: document.index_by_id,
                                          theme: theme)
    text = Nokogiri::XML("<svg>#{labels.render}</svg>").css("text")
      .find { |node| node.text == "+items" }

    expect(text["style"]).to include("font-family:Cambria;")
    expect(text["textLength"]).to eq("29")
  end

  it "uses an explicitly overridden global family for connector text" do
    theme = Ea::Theme::Registry.default.with(font_family: "Helvetica")
    labels = described_class.new(diagram, model_index: document.index_by_id,
                                          theme: theme)

    expect(labels.render).to include("font-family:Helvetica;")
  end

  context "when association has no properties" do
    let(:relationship) do
      Ea::Model::Association.new(id: "r1", source_id: "x", target_id: "y")
    end

    it "emits no labels" do
      expect(renderer.render).to eq("")
    end
  end

  context "when label boxes are absent" do
    let(:connector) do
      Ea::Model::DiagramConnector.new(
        id: "dc1",
        relationship_ref: relationship.id,
        waypoints: [
          Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 0, y: 0)),
          Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 100, y: 0))
        ]
      )
    end

    it "emits multiplicity labels at EA default positions" do
      # target end (100,0): mult at 18px along, 21px below in flipped space
      svg = renderer.render
      expect(svg).to include("0..1")
      expect(svg).to include("82.00")
    end
  end

  describe "label-specific typography" do
    it "uses theme39 Cambria7pt for both end and midpoint labels" do
      relationship.name = "association name"
      diagram.style_ex = "Theme=:39;"
      labels = described_class.new(diagram, model_index: document.index_by_id, theme: diagram.theme)
      nodes = Nokogiri::XML("<svg>#{labels.render}</svg>").css("text")

      expect(nodes.map(&:text)).to include("+items", "association name")
      expect(nodes.map { |node| node["style"] }.uniq).to all(include("font-family:Cambria;", "font-size:7pt;"))
    end

    it "preserves default, unknown and custom global font fallbacks" do
      themes = [Ea::Theme::Registry.default, Ea::Theme::Registry.lookup("unknown-label-theme"),
                Ea::Theme::Definition.new(id: "custom-labels", font_family: "Arial",
                                          font_size: 11, font_size_unit: "px")]
      expected = [["Yu Gothic UI", "13px"], ["Yu Gothic UI", "13px"], ["Arial", "11px"]]
      themes.zip(expected).each do |theme, (family, size)|
        svg = described_class.new(diagram, model_index: document.index_by_id, theme: theme).render

        expect(svg).to include("font-family:#{family};", "font-size:#{size};")
      end
    end
  end

  describe "labels on emitted two-point docks" do
    include LabelAnchorHelpers

    # {0016F797} dc:73:481: the stored endpoints have x=570,
    # but the anchor ray clips the drawn boxes at x=651.
    let(:docked_connector) do
      Ea::Model::DiagramConnector.new(
        id: "dock", relationship_ref: "a", connector_type: "Aggregation",
        style: { mode: "1", lwidth: "2" },
        source_anchor: Ea::Model::Point.new(x: 651, y: 1076),
        target_anchor: Ea::Model::Point.new(x: 651, y: 711),
        waypoints: [[570, 920], [570, 791]].map do |x, y|
          Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: x, y: y))
        end,
        label_boxes: { llb: { "ox" => 22, "oy" => 0, "alignment" => 1 },
                       llt: { "ox" => -9, "oy" => -2, "alignment" => 1 } }
      )
    end
    let(:drawn_bounds) do
      { "source" => Ea::Model::Bounds.new(x: 470, y: 920, width: 396, height: 312),
        "target" => Ea::Model::Bounds.new(x: 570, y: 711, width: 120, height: 80) }
    end

    it "anchors multiplicity at the emitted outer-stroke dock" do
      positions = anchor_label_positions(docked_connector, bounds: drawn_bounds)

      # Reference [216,426], translated from model by [-460,-487].
      expect(positions["0..1"]).to eq([676, 913])
      expect(positions["+trafficVolumeAttribute"]).to eq([642, 921])
    end

    it "follows the emitted header row-slot adjustment" do
      docked_connector.source_anchor = Ea::Model::Point.new(x: 50, y: 50)
      docked_connector.target_anchor = Ea::Model::Point.new(x: 250, y: 50)
      bounds = {
        "source" => Ea::Model::Bounds.new(x: 0, y: 0, width: 100, height: 100),
        "target" => Ea::Model::Bounds.new(x: 200, y: 0, width: 100, height: 100)
      }
      positions = anchor_label_positions(
        docked_connector, bounds: bounds, dividers: { "source" => 50, "target" => 50 }
      )

      expect(positions["0..1"]).to eq([126, 78])
      expect(positions["+trafficVolumeAttribute"]).to eq([95, 54])
    end

    it "keeps parsed anchors when drawn bounds are unavailable or incomplete" do
      [nil, drawn_bounds.slice("source")].each do |bounds|
        positions = anchor_label_positions(docked_connector, bounds: bounds)

        expect(positions["0..1"]).to eq([595, 914])
        expect(positions["+trafficVolumeAttribute"]).to eq([561, 922])
      end
    end

    it "keeps stored bent-route anchors even when drawn bounds differ" do
      docked_connector.waypoints.insert(
        1, Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 570, y: 850))
      )
      positions = anchor_label_positions(docked_connector, bounds: drawn_bounds)

      expect(positions["0..1"]).to eq([595, 914])
      expect(positions["+trafficVolumeAttribute"]).to eq([561, 922])
    end
  end

  describe "stored directions after endpoint clipping" do
    include LabelHeadingHelpers

    let(:heading_record) do
      { points: [[493, 251], [493, 173]], anchors: [[450, 296], [453, 103]],
        box: { "ox" => 24, "oy" => -21, "alignment" => 1 } }
    end
    let(:heading_connector) { build_heading_connector(heading_record) }
    let(:heading_bounds) do
      { "source" => Ea::Model::Bounds.new(x: 324, y: 251, width: 250, height: 88),
        "target" => Ea::Model::Bounds.new(x: 335, y: 31, width: 248, height: 142) }
    end

    it "seats complete reference clusters at their actual source exit faces" do
      path = File.expand_path("../../../support/label_dock_faces.json", __dir__)
      JSON.parse(File.read(path), symbolize_names: true).each do |record|
        positions = heading_positions(
          build_heading_connector(record), heading_bounds_for(record), role: record[:role], mult: record[:mult]
        )
        expect(positions["+#{record[:role]}"]).to eq(record[:expected][0]), record[:case]
        expect(positions["«property»"]).to eq(record[:expected][1]), record[:case]
        expect(positions[record[:mult]]).to eq(record[:expected][2]), record[:case]
      end
    end

    it "keeps diagonal labels when either drawn endpoint is unresolved" do
      heading_connector.waypoints.last.position.x = 515
      [nil, heading_bounds.slice("source"), heading_bounds.slice("target")].each do |bounds|
        positions = heading_positions(heading_connector, bounds)

        expect(positions["+trafficAreaStructureAttribute"]).to eq([517, 272])
        expect(positions["0..1"]).to eq([503, 253])
      end
    end

    it "keeps manual bent routes on their stored diagonal heading" do
      heading_connector.waypoints.last.position.x = 515
      heading_connector.waypoints << Ea::Model::Waypoint.new(position: heading_point([515, 100]))
      positions = heading_positions(heading_connector, heading_bounds)

      expect(positions["+trafficAreaStructureAttribute"]).to eq([517, 272])
      expect(positions["0..1"]).to eq([503, 253])
    end

    it "keeps diagonal corner docks ambiguous on logical and outer edges" do
      heading_connector.waypoints = [[100, 100], [200, 200]].map do |x, y|
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: x, y: y))
      end
      heading_connector.source_anchor = heading_point([50, 50])
      heading_connector.target_anchor = heading_point([250, 250])
      bounds = heading_bounds_for(source: [0, 0, 100, 100], target: [200, 200, 100, 100])
      { "0" => [[124, 121], [110, 102]], "2" => [[125, 122], [111, 103]] }.each do |width, expected|
        heading_connector.style[:lwidth] = width
        positions = heading_positions(heading_connector, bounds)

        expect(positions["+trafficAreaStructureAttribute"]).to eq(expected[0])
        expect(positions["0..1"]).to eq(expected[1])
      end
      heading_connector.waypoints.last.position = heading_point([100, 0])
      positions = heading_positions(heading_connector, bounds)

      expect(positions["+trafficAreaStructureAttribute"]).to eq([125, 122])
      expect(positions["0..1"]).to eq([111, 103])
    end

    it "keeps an upward stored seat at the final slanted dock" do
      positions = heading_positions(heading_connector, heading_bounds)

      expect(positions["+trafficAreaStructureAttribute"]).to eq([285, 223])
      expect(positions["«property»"]).to eq([326, 235])
      expect(positions["0..1"]).to eq([463, 242])
      expect(positions["+owner"]).to eq([456, 167])
    end

    it "uses the known top face for a diagonal stored route" do
      heading_connector.waypoints.last.position.x = 515
      positions = heading_positions(heading_connector, heading_bounds)

      expect(positions["+trafficAreaStructureAttribute"]).to eq([285, 223])
      expect(positions["0..1"]).to eq([463, 242])
    end

    it "keeps diagonal offsets when an outside origin enters the source box" do
      connector = build_heading_connector(
        points: [[100, 50], [-100, 30]], anchors: [[150, 50], [-150, 30]],
        box: heading_record[:box]
      )
      bounds = heading_bounds_for(source: [0, 0, 100, 100], target: [-200, 0, 100, 100])
      positions = heading_positions(connector, bounds)

      expect(positions["+trafficAreaStructureAttribute"]).to eq([125, 67])
      expect(positions["0..1"]).to eq([111, 48])
    end

    it "uses the known bottom face when the stored upward route is stale" do
      heading_connector.target_anchor.y = 600
      heading_bounds["target"] = Ea::Model::Bounds.new(x: 335, y: 500,
                                                       width: 248, height: 142)
      positions = heading_positions(heading_connector, heading_bounds)

      expect(positions["+trafficAreaStructureAttribute"]).to eq([280, 334])
      expect(positions["0..1"]).to eq([468, 353])
    end

    it "keeps the final cardinal direction when the stored route is diagonal" do
      heading_connector.waypoints.last.position.x = 515
      heading_connector.target_anchor.x = 450
      positions = heading_positions(heading_connector, heading_bounds)

      expect(positions["+trafficAreaStructureAttribute"]).to eq([285, 223])
      expect(positions["0..1"]).to eq([463, 242])
    end

    context "with a target dock that clips a stored horizontal leg" do
      let(:target_bounds) do
        { "source" => Ea::Model::Bounds.new(x: 984, y: 140, width: 120, height: 100),
          "target" => Ea::Model::Bounds.new(x: 700, y: 144, width: 176, height: 100) }
      end

      def clipped_target_connector(stored_target_y)
        build_heading_connector(
          points: [[984, 188], [876, stored_target_y]],
          anchors: [[1044, 190], [788, 194]],
          box: { "ox" => 5, "oy" => 7, "alignment" => 1 }
        )
      end

      it "seats the target role at the stored cardinal leg's corner" do
        positions = heading_positions(clipped_target_connector(188), target_bounds)

        expect(positions["+owner"]).to eq([885, 192])
      end

      it "keeps the stored offset when the stored leg is itself diagonal" do
        positions = heading_positions(clipped_target_connector(196), target_bounds)

        expect(positions["+owner"]).to eq([882, 185])
      end
    end
  end

  describe "stored source-end label seats" do
    include LabelSeatHelpers
    include LabelPresenceHelpers

    # Reference records of the pinned 220 corpus (20251010_current_plateau_v5.1.qea).
    # `shift` is the reference-minus-model translation from the diagram's
    # rectangles; `mult`/`role` are the reference SVG text coordinates.
    #   up:    {0114FD24-...} dc:190:1473
    #   right: {84A9C65B-...} dc:154:1083, {87476527-...} dc:172:1391
    let(:up_leg) do
      { waypoints: [[158, 341], [158, 251], [520, 251], [520, 202]],
        label_boxes: { llb: { "ox" => 15, "oy" => -4, "alignment" => 1 },
                       llt: { "ox" => 16, "oy" => -25, "alignment" => 1 } },
        role: "consBaseAttribute", multiplicity: "0..1",
        shift: [3, 2], mult: [179, 333] }
    end
    let(:right_legs) do
      [{ waypoints: [[742, 240], [933, 240], [933, 175]],
         label_boxes: { llb: { "ox" => 22, "oy" => 0, "alignment" => 1 },
                        llt: { "ox" => 42, "oy" => 37, "alignment" => 1 } },
         role: "ifcIntBuildingInstallationAttribute", multiplicity: "0..*",
         shift: [-82, -30], mult: [685, 225], role_at: [705, 240] },
       { waypoints: [[600, 800], [738, 800], [738, 724]],
         label_boxes: { llb: { "ox" => 7, "oy" => 9, "alignment" => 0 },
                        llt: { "ox" => 53, "oy" => 32, "alignment" => 0 } },
         role: "lod0Geometry", multiplicity: "0..1",
         shift: [-55, 5], mult: [555, 829], role_at: [601, 830] }]
    end

    it "seats an upward leg's multiplicity at the reference position" do
      texts = source_texts(up_leg)

      expect(in_reference_space(texts["0..1"], up_leg)).to eq(up_leg[:mult])
    end

    it "keeps the role plain on an upward leg" do
      expect(source_texts(up_leg)["+consBaseAttribute"]).to eq([174, 366])
    end

    it "seats a rightward leg's role and multiplicity at the reference positions" do
      right_legs.each do |record|
        texts = source_texts(record)

        expect(in_reference_space(texts[record[:multiplicity]], record))
          .to eq(record[:mult])
        expect(in_reference_space(texts["+#{record[:role]}"], record))
          .to eq(record[:role_at])
      end
    end

    it "seats the stereotype line at the reference gap on 7pt labels" do
      texts = source_texts(right_legs[0])

      # {84A9C65B} dc:154:1083: role y 240, «property» y 252 in the reference.
      expect(in_reference_space(texts["«property»"], right_legs[0]).last)
        .to eq(252)
    end

    it "keeps size + 6 below the role for other label sizes" do
      texts = source_texts(right_legs[0], font_size: 9)

      expect(texts["«property»"].last - texts["+ifcIntBuildingInstallationAttribute"].last)
        .to eq(15)
    end

    it "keeps the plain offsets for other label sizes" do
      texts = source_texts(up_leg, font_size: 9)

      expect(texts["0..1"]).to eq([158 + 15, 341 + 4])
    end

    it "keeps the plain offsets for a rotated box" do
      up_leg[:label_boxes][:llb]["rotation"] = 90
      right_legs[0][:label_boxes][:llt]["rotation"] = 90

      expect(source_texts(up_leg)["0..1"]).to eq([158 + 15, 341 + 4])
      expect(source_texts(right_legs[0])["+ifcIntBuildingInstallationAttribute"])
        .to eq([742 + 42, 240 - 37])
    end

    it "keeps the plain offsets for a downward and a leftward first leg" do
      down = up_leg.merge(waypoints: [[158, 341], [158, 430], [520, 430]])
      left = up_leg.merge(waypoints: [[158, 341], [60, 341], [60, 430]])

      expect(source_texts(down)["0..1"]).to eq([158 + 15, 341 + 4])
      expect(source_texts(left)["0..1"]).to eq([158 + 15, 341 + 4])
    end

    it "keeps the plain offsets for symbol-keyed and partial boxes" do
      right = { waypoints: [[100, 200], [300, 200]], role: "items",
                multiplicity: "0..*", stereotype: "property" }
      symbols = label_seat_positions(
        **right, label_boxes: { llt: { ox: 46, oy: -16 },
                                llb: { ox: 8, oy: 3 } }
      )
      partial = label_seat_positions(
        **right, label_boxes: { llt: { "ox" => 46 }, llb: { "oy" => 3 } }
      )

      expect(symbols.assoc("+items").last).to eq([146, 216])
      expect(partial.assoc("+items").last).to eq([146, 200])
    end

    it "keeps the zero-box multiplicity default" do
      up_leg[:label_boxes][:llb] = { "ox" => 0, "oy" => 0 }

      expect(source_texts(up_leg)["0..1"]).to eq([158 + 12, 341 + 15])
    end

    it "keeps the target end's stored offsets when it carries its own data" do
      boxes = up_leg[:label_boxes].merge(
        lrb: { "ox" => 15, "oy" => -4, "alignment" => 1 },
        lrt: { "ox" => 16, "oy" => -25, "alignment" => 1 }
      )
      texts = label_presence_texts(
        waypoints: up_leg[:waypoints], label_boxes: boxes,
        ends: { source: { role: "consBaseAttribute", mult: "0..1" },
                target: { role: "owner", mult: "1" } }
      ).to_h

      expect(texts["1"]).to eq([520 + 15, 202 + 4])
      expect(texts["+owner"]).to eq([520 + 16, 202 + 25])
    end
  end

  describe "end-label ownership" do
    include LabelPresenceHelpers

    let(:source_boxes) do
      { llt: { "ox" => 10, "oy" => -15 }, llb: { "ox" => 8, "oy" => 3 } }
    end
    let(:target_boxes) do
      { lrt: { "ox" => 12, "oy" => -14 }, lrb: { "ox" => 9, "oy" => 4 } }
    end
    let(:source_data) { { role: "items", mult: "0..*", stereotype: "property" } }

    it "draws one cluster when the data end is boxed and the other end is not" do
      texts = label_presence_texts(ends: { source: source_data },
                                   label_boxes: source_boxes)

      expect(label_presence_contents(texts)).to eq(["+items", "«property»", "0..*"])
    end

    it "draws one cluster at the boxed end for the mirrored target case" do
      texts = label_presence_texts(
        ends: { target: { role: "items", mult: "0..*" } },
        label_boxes: target_boxes
      )

      expect(label_presence_contents(texts)).to eq(["+items", "0..*"])
    end

    it "draws one cluster at the data end when only the other end is boxed" do
      texts = label_presence_texts(ends: { source: source_data },
                                   label_boxes: target_boxes)

      expect(label_presence_contents(texts)).to eq(["+items", "«property»", "0..*"])
    end

    it "draws one cluster when both ends are boxed and only one carries data" do
      texts = label_presence_texts(
        ends: { source: source_data },
        label_boxes: source_boxes.merge(target_boxes)
      )

      expect(label_presence_contents(texts)).to eq(["+items", "«property»", "0..*"])
    end

    it "draws a data-less end's own stereotype alone at its box" do
      texts = label_presence_texts(
        ends: { source: source_data,
                target: { stereotype: "property" } },
        label_boxes: source_boxes.merge(target_boxes)
      )

      expect(label_presence_contents(texts))
        .to eq(["+items", "«property»", "0..*", "«property»"])
      expect(texts.last.last).to eq([300 + 12, 200 + 14])
    end

    it "draws nothing for stereotypes when no end carries data" do
      texts = label_presence_texts(
        ends: { source: { stereotype: "property" },
                target: { stereotype: "property" } },
        label_boxes: source_boxes.merge(target_boxes)
      )

      expect(texts).to eq([])
    end

    it "draws a role-only end once, without multiplicity" do
      texts = label_presence_texts(
        ends: { source: { role: "items" } }, label_boxes: source_boxes
      )

      expect(label_presence_contents(texts)).to eq(["+items"])
    end

    it "draws a multiplicity-only end once" do
      texts = label_presence_texts(
        ends: { source: { mult: "0..*" } }, label_boxes: source_boxes
      )

      expect(label_presence_contents(texts)).to eq(["0..*"])
    end

    it "draws a qualified role's multiplicity once and no role text" do
      texts = label_presence_texts(
        ends: { source: { role: "pkg::items", mult: "0..*" } },
        label_boxes: source_boxes
      )

      expect(label_presence_contents(texts)).to eq(["0..*"])
    end

    it "keeps a «Type» stereotype with its cluster and alone at a data-less end" do
      texts = label_presence_texts(
        ends: { source: source_data.merge(stereotype: "Type"),
                target: { stereotype: "Type" } },
        label_boxes: source_boxes.merge(target_boxes)
      )

      expect(label_presence_contents(texts))
        .to eq(["+items", "«Type»", "0..*", "«Type»"])
    end

    it "keeps both default clusters when neither end is boxed" do
      texts = label_presence_texts(ends: { source: source_data },
                                   label_boxes: {})

      expect(label_presence_contents(texts).count("+items")).to eq(2)
    end

    it "keeps each end's own cluster when both carry data" do
      texts = label_presence_texts(
        ends: { source: source_data, target: { role: "owner", mult: "1" } },
        label_boxes: source_boxes.merge(target_boxes)
      )

      expect(label_presence_contents(texts)).to include("+items", "+owner", "0..*", "1")
    end
  end
end
