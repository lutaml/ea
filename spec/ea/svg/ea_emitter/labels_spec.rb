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

  describe "stored source-end label seats" do
    include LabelSeatHelpers

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

    def source_texts(record, **overrides)
      label_seat_positions(
        **record.slice(:waypoints, :label_boxes, :role, :multiplicity),
        stereotype: "property", **overrides
      ).each_with_object({}) { |(text, xy), seen| seen[text] ||= xy }
    end

    def in_reference_space(point, record)
      [point[0] + record[:shift][0], point[1] + record[:shift][1]]
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

    it "keeps the target end's stored offsets" do
      boxes = up_leg[:label_boxes].merge(
        lrb: { "ox" => 15, "oy" => -4, "alignment" => 1 },
        lrt: { "ox" => 16, "oy" => -25, "alignment" => 1 }
      )
      target = label_seat_positions(
        **up_leg.slice(:waypoints, :role, :multiplicity),
        label_boxes: boxes, stereotype: "property"
      ).select { |text, _| text == "0..1" }.last

      expect(target.last).to eq([520 + 15, 202 + 4])
    end
  end
end
