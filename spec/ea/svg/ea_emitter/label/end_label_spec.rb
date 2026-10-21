# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::Label::EndLabel do
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
  let(:classifier_a) do
    Ea::Model::Klass.new(id: "c1", name: "A", properties: [source_property])
  end
  let(:association) do
    Ea::Model::Association.new(id: "r1", source_id: "p_src", target_id: "p_tgt")
  end
  let(:document) do
    Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      classifiers: [classifier_a],
      relationships: [association]
    )
  end
  let(:model_index) { document.index_by_id }
  let(:connector) do
    Ea::Model::DiagramConnector.new(
      id: "dc1",
      relationship_ref: association.id,
      connector_type: "Association",
      direction: "Source -> Destination",
      source_stereotype: "Property",
      target_stereotype: nil,
      waypoints: [
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 0, y: 0)),
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 100, y: 0))
      ],
      label_boxes: {
        llb: { "ox" => 0, "oy" => 0 },
        llt: { "ox" => 10, "oy" => 15 }
      }
    )
  end

  def renderer
    described_class.new(canvas: nil, model_index: model_index,
                        document: document, theme: Ea::Theme::Registry.default,
                        font_family: "Carlito", font_size: 7, font_unit: "pt")
  end

  it "emits role name + «Property» + multiplicity at the source box" do
    out = renderer.texts(text_box: { "ox" => 10, "oy" => 15 },
                          mult_box: { "ox" => 0, "oy" => 0 },
                          anchor: [0, 0], connector: connector,
                          end_kind: :source)
    joined = out.join
    expect(joined).to include("+items")
    expect(joined).to include("«Property»")
    expect(joined).to include("0..*")
  end

  it "omits «Property» when the end carries no stereotype" do
    bare = Ea::Model::DiagramConnector.new(
      id: "dc2",
      relationship_ref: association.id,
      connector_type: "Association",
      direction: "Destination -> Source",
      waypoints: connector.waypoints,
      label_boxes: connector.label_boxes
    )
    out = renderer.texts(text_box: { "ox" => 10, "oy" => 15 },
                          mult_box: { "ox" => 0, "oy" => 0 },
                          anchor: [0, 0], connector: bare,
                          end_kind: :source)
    joined = out.join
    expect(joined).to include("+items")
    expect(joined).not_to include("«Property»")
  end

  it "renders the stored cardinality verbatim when present" do
    source_property.multiplicity_raw = "*"
    out = renderer.texts(text_box: { "ox" => 10, "oy" => 15 },
                          mult_box: { "ox" => 0, "oy" => 0 },
                          anchor: [0, 0], connector: connector,
                          end_kind: :source)
    joined = out.join
    expect(joined).not_to include("0..*")
    expect(joined).to include(">*</text>")
  end

  it "renders association raw cards verbatim on the fallback path" do
    assoc = Ea::Model::Association.new(
      id: "r3", source_id: "c1", target_id: "c2",
      source_multiplicity_raw: "1..1",
      source_multiplicity_lower: 1,
      source_multiplicity_upper: 1
    )
    doc = Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      classifiers: [
        Ea::Model::Klass.new(id: "c1", name: "A"),
        Ea::Model::Klass.new(id: "c2", name: "B")
      ],
      relationships: [assoc]
    )
    conn = Ea::Model::DiagramConnector.new(
      id: "dc3", relationship_ref: assoc.id,
      connector_type: "Association", direction: "Source -> Destination"
    )
    r = described_class.new(canvas: nil, model_index: doc.index_by_id,
                            document: doc, theme: Ea::Theme::Registry.default,
                            font_family: "Carlito", font_size: 7, font_unit: "pt")
    out = r.texts(text_box: { "ox" => 5, "oy" => 5 },
                  mult_box: { "ox" => 2, "oy" => 2 }, anchor: [0, 0],
                  connector: conn, end_kind: :source)
    expect(out.join).to include("1..1")
    expect(out.join).not_to include(">1<")
  end

  it "returns [] when no text or mult box is positioned" do
    out = renderer.texts(text_box: nil, mult_box: nil,
                          anchor: [0, 0], connector: connector,
                          end_kind: :source)
    expect(out).to eq([])
  end

  it "falls back to the opposite-end role when source end has none" do
    # Target-only role: the association has only a target_role_name
    # set, no source role. Only the source-side LLT box exists.
    # EndLabel should render the target-side role at the source box.
    target_only_assoc = Ea::Model::Association.new(
      id: "r2",
      source_id: "c1",
      target_id: "c2",
      source_role_name: nil,
      target_role_name: "things",
      target_multiplicity_lower: 0,
      target_multiplicity_upper: 1
    )
    doc = Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      classifiers: [
        Ea::Model::Klass.new(id: "c1", name: "A"),
        Ea::Model::Klass.new(id: "c2", name: "B")
      ],
      relationships: [target_only_assoc]
    )
    conn = Ea::Model::DiagramConnector.new(
      id: "dc2",
      relationship_ref: target_only_assoc.id,
      waypoints: [
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 0, y: 0)),
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 100, y: 0))
      ]
    )
    r = described_class.new(canvas: nil, model_index: doc.index_by_id,
                            document: doc, theme: Ea::Theme::Registry.default,
                            font_family: "Carlito", font_size: 7, font_unit: "pt")
    out = r.texts(text_box: { "ox" => 5, "oy" => 5 },
                  mult_box: nil, anchor: [0, 0], connector: conn,
                  end_kind: :source)
    expect(out.join).to include("+things")
  end

  describe "stored directional source seats" do
    include LabelUpwardPropertyHelpers

    let(:traffic) do
      { role: "trafficVolumeAttribute", anchor: [191, 432],
        box: { "ox" => -9, "oy" => -2, "alignment" => 1 } }
    end

    it "seats zero-offset multiplicities in their actual source directions" do
      records = [
        { role: "frnDataQualityAttribute", mult: "1", anchor: [238, 215], heading: [0, -45],
          style: { mode: "3", lwidth: "2", tree: "V" }, expected: [241, 209] },
        { role: "trafficArea", mult: "0..*", anchor: [258, 470], heading: [133, 0],
          style: { mode: "3", lwidth: "0" }, expected: [261, 485] }
      ]
      records.each do |record|
        positions = upward_property_positions(
          record.merge(box: traffic[:box]),
          heading: record[:heading], style: record[:style],
          mult_box: { "ox" => 0, "oy" => 0, "alignment" => 1 }
        )
        expect(positions[record[:mult]]).to eq(record[:expected])
      end
    end

    it "keeps zero-box defaults outside the measured font and presentation" do
      controls = [{ family: "Carlito" }, { size: 10 }, { unit: "px" },
                  { mult_box: { "ox" => 0, "oy" => 0, "bold" => true } },
                  { mult_box: { "ox" => 0, "oy" => 0, "rotation" => 90 } },
                  { heading: [1, -100] }]
      controls.each do |options|
        positions = upward_property_positions(
          traffic, mult_box: { "ox" => 0, "oy" => 0 }, **options
        )
        expect(positions["0..1"]).to eq([203, 447])
      end
    end

    it "keeps the source default on a perfect L with both boxes zero" do
      positions = upward_property_positions(
        traffic,
        box: { "ox" => 0, "oy" => 0 }, mult_box: { "ox" => 0, "oy" => 0 },
        heading: [100, 0], tree: true
      )

      expect(positions["0..1"]).to eq([194, 432])
    end

    it "right-aligns plain upward roles at their stored corners" do
      records = [
        { role: "bldgUsecaseAttribute", anchor: [1727, 440],
          box: { "ox" => -17, "oy" => -19, "alignment" => 1 }, expected: [1611, 415] },
        { role: "squareUrbanPlanAttribute", anchor: [526, 566],
          box: { "ox" => -10, "oy" => -2, "alignment" => 0 }, expected: [394, 558] },
        { role: "roleThree", anchor: [384, 161],
          box: { "ox" => -6, "oy" => -5, "alignment" => 0 }, expected: [326, 150] }
      ]
      records.each do |record|
        positions = upward_property_positions(record, stereotype: "", style: { mode: "3", lwidth: "2" })
        expect(positions["+#{record[:role]}"]).to eq(record[:expected])
      end
    end

    it "right-aligns plain downward source roles independently of their multiplicity" do
      records = [
        { role: "role a", mult: "0..1", anchor: [72, 80],
          box: { "ox" => -1, "oy" => 2, "alignment" => 1 }, expected: [33, 97] },
        { role: "role c", mult: "0..*", anchor: [67, 80],
          box: { "ox" => -3, "oy" => 3, "alignment" => 1 }, expected: [27, 98] }
      ]
      records.each do |record|
        positions = upward_property_positions(
          record, stereotype: "", heading: [0, 100], style: { mode: "3", lwidth: "0" },
                  mult_box: { "ox" => 0, "oy" => 0 }
        )

        expect(positions["+#{record[:role]}"]).to eq(record[:expected])
        expect(positions[record[:mult]]).to eq([record[:anchor][0] + 8, record[:anchor][1] + 15])
        expect(positions.keys).not_to include("«property»")
      end
    end

    it "right-aligns plain upward target roles while preserving their cardinality" do
      records = [
        { role: "role c", mult: "0..*", anchor: [72, 213],
          box: { "ox" => 0, "oy" => 0, "alignment" => 1 }, expected: [35, 206] },
        { role: "role d", mult: "0..*", anchor: [67, 188],
          box: { "ox" => -1, "oy" => 0, "alignment" => 1 }, expected: [27, 181] },
        { role: "target", mult: "1", anchor: [310, 800],
          box: { "ox" => 0, "oy" => 0, "alignment" => 0 }, expected: [271, 793] }
      ]
      records.each do |record|
        positions = upward_property_positions(
          record, stereotype: "", end_kind: :target,
                  heading: [0, -100], style: { mode: "3", lwidth: "0" }, mult_box: { "ox" => 0, "oy" => 0 }
        )

        expect(positions["+#{record[:role]}"]).to eq(record[:expected])
        expect(positions[record[:mult]]).to eq([record[:anchor][0] + 8, record[:anchor][1] - 7])
      end
    end

    it "keeps unproven plain vertical role regimes unchanged" do
      controls = [{ family: "Carlito" }, { size: 9 }, { unit: "px" },
                  { type: "Aggregation" }, { style: { mode: "2", lwidth: "0" } },
                  { style: { mode: "3", lwidth: "2" } },
                  { style: { mode: "3", lwidth: "0", tree: "V" } },
                  { box: traffic[:box].merge("alignment" => nil) },
                  { box: traffic[:box].merge("rotation" => 90) },
                  { box: traffic[:box].merge("italic" => true) },
                  { box: traffic[:box].transform_keys(&:to_sym) }, { box: nil }]
      controls.each do |options|
        positions = upward_property_positions(
          traffic, stereotype: "", style: { mode: "3", lwidth: "0" }, heading: [0, 100], **options
        )
        expected = options[:box].nil? && options.key?(:box) ? nil : [182, 434]
        expect(positions["+trafficVolumeAttribute"]).to eq(expected)
      end
      %i[source target].each do |end_kind|
        positions = upward_property_positions(
          traffic, end_kind: end_kind, stereotype: "Type", target_stereotype: "Type",
                   heading: [0, end_kind == :source ? 100 : -100], style: { mode: "3", lwidth: "0" }
        )
        expect(positions["+trafficVolumeAttribute"]).to eq([182, 434])
        expect(positions.keys).to include("«Type»")
      end
    end

    it "keeps nonvertical, opposite-facing and unmeasured glyph role seats" do
      [[:source, [1, 100]], [:source, nil], [:target, [1, -100]],
       [:target, [0, 100]], [:target, nil]].each do |end_kind, heading|
        positions = upward_property_positions(
          traffic, stereotype: "", end_kind: end_kind,
                   style: { mode: "3", lwidth: "0" }, heading: heading
        )
        expect(positions["+trafficVolumeAttribute"]).to eq([182, 434])
      end
      positions = upward_property_positions(
        traffic.merge(role: "traffic☃"), stereotype: "", heading: [0, 100],
                                         style: { mode: "3", lwidth: "0" }
      )
      expect(positions["+traffic☃"]).to eq([182, 434])
    end

    it "preserves unmeasured fonts, styles and headings for plain roles" do
      controls = [{ family: "Carlito" }, { size: 10 }, { unit: "px" }, { stereotype: "Type" },
                  { box: traffic[:box].merge("bold" => true) },
                  { box: traffic[:box].merge("rotation" => 90) },
                  { box: traffic[:box].merge("alignment" => nil) },
                  { style: { mode: "2", lwidth: "2" } },
                  { style: { mode: "3", lwidth: "2", tree: "LH" } }, { heading: [1, -100] }]
      controls.each do |options|
        positions = upward_property_positions(
          traffic, stereotype: "", style: { mode: "3", lwidth: "2" }, **options
        )
        expect(positions["+trafficVolumeAttribute"]).to eq([182, 434])
      end
      positions = upward_property_positions(
        traffic.merge(role: "traffic☃"), stereotype: "", style: { mode: "3", lwidth: "2" }
      )
      expect(positions["+traffic☃"]).to eq([182, 434])
    end

    it "seats upward target multiplicities from zero stored boxes" do
      records = [{ role: "target", mult: "1", anchor: [310, 800], expected: [318, 793] },
                 { role: "role c", mult: "0..*", anchor: [72, 213], expected: [80, 206] }]
      records.each do |record|
        positions = upward_property_positions(
          record.merge(box: { "ox" => 5, "oy" => 7 }),
          end_kind: :target,
          heading: [0, -100], mult_box: { "ox" => 0, "oy" => 0, "alignment" => 1 }
        )
        expect(positions[record[:mult]]).to eq(record[:expected])
        expect(positions["+#{record[:role]}"]).to eq([record[:anchor][0] + 5, record[:anchor][1] - 7])
      end
    end

    it "preserves target defaults outside the measured zero-box upward seat" do
      controls = [{ family: "Carlito" }, { size: 10 }, { unit: "px" },
                  { heading: [1, -100] }, { heading: [0, 100] }, { heading: nil },
                  { mult_box: { "ox" => 0, "oy" => 0, "bold" => true } }]
      record = { role: "owner", mult: "0..*", anchor: [72, 213], box: { "ox" => 5, "oy" => 7 } }
      controls.each do |options|
        positions = upward_property_positions(
          record, end_kind: :target, heading: [0, -100], mult_box: { "ox" => 0, "oy" => 0 }, **options
        )
        expect(positions["0..*"]).to eq([84, 228])
      end
    end

    it "preserves a target perfect-L default and explicit target offsets" do
      record = { role: "owner", mult: "0..*", anchor: [72, 213], box: { "ox" => 0, "oy" => 0 } }
      tree = upward_property_positions(
        record, end_kind: :target, tree: true, heading: [0, -100], mult_box: { "ox" => 0, "oy" => 0 }
      )
      explicit = upward_property_positions(
        record, end_kind: :target, heading: [0, -100], mult_box: { "ox" => 5, "oy" => 7 }
      )

      expect(tree["0..*"]).to eq([80, 205])
      expect(explicit["0..*"]).to eq([77, 206])
    end

    it "seats the direct role at its published reference position" do
      positions = upward_property_positions(traffic)

      expect(positions["+trafficVolumeAttribute"]).to eq([20, 424])
      expect(positions["«property»"]).to eq([47, 436])
    end

    it "seats held-out roles on different stored tree layouts" do
      records = [
        { role: "consBaseAttribute", anchor: [161, 343],
          box: { "ox" => 16, "oy" => -25, "alignment" => 1 }, expected: [34, 312] },
        { role: "tunFunctionalAttribute", anchor: [1242, 297],
          box: { "ox" => 161, "oy" => -15, "alignment" => 1 }, expected: [1238, 276] }
      ]
      records.each do |record|
        expect(upward_property_positions(record)["+#{record[:role]}"]).to eq(record[:expected])
      end
    end

    it "seats leftward property roles without moving their multiplicity" do
      records = [
        { role: "auxiliaryTrafficArea", anchor: [723, 470],
          box: { "ox" => 0, "oy" => 0, "alignment" => 1 }, expected: [570, 463] },
        { role: "cityObjectMember", anchor: [349, 280],
          box: { "ox" => 1, "oy" => 0, "alignment" => 1 }, expected: [207, 273] },
        { role: "reliefComponent", anchor: [425, 332],
          box: { "ox" => 0, "oy" => 0, "alignment" => 1 }, expected: [286, 325] }
      ]
      records.each do |record|
        positions = upward_property_positions(record, heading: [-100, 0], style: { mode: "3", lwidth: "0" })

        expect(positions["+#{record[:role]}"]).to eq(record[:expected])
        expect(positions["0..1"]).to eq([record[:anchor][0] + record[:box]["ox"], record[:anchor][1]])
      end
    end

    it "seats leftward multiplicity from zero and explicit stored offsets" do
      records = [
        { role: "auxiliaryTrafficArea", anchor: [723, 470], mult: "0..*",
          box: { "ox" => 0, "oy" => 0, "alignment" => 1 },
          mult_box: { "ox" => 0, "oy" => 0, "alignment" => 1 },
          style: { mode: "3", lwidth: "0" }, expected: [706, 485] },
        { role: "tranFacilityIdAttribute", anchor: [801, 485], mult: "0..1",
          box: { "ox" => 0, "oy" => 0, "alignment" => 1 },
          mult_box: { "ox" => -22, "oy" => -24, "alignment" => 0 },
          style: { mode: "3", lwidth: "2", tree: "H" }, expected: [760, 476] }
      ]
      records.each do |record|
        positions = upward_property_positions(
          record, heading: [-100, 0], style: record[:style], mult_box: record[:mult_box]
        )

        expect(positions[record[:mult]]).to eq(record[:expected])
      end
    end

    it "seats leftward property multiplicity on every route style, not only the role-seat styles" do
      records = [
        { anchor: [800, 544], mult: "0..*", style: { mode: "3", lwidth: "2", tree: "OS" }, expected: [783, 559] },
        { anchor: [649, 270], mult: "0..1", style: { mode: "2", lwidth: "2" }, expected: [630, 285] },
        { anchor: [763, 564], mult: "0..1", style: { mode: "1", lwidth: "2" }, expected: [744, 579] }
      ]
      records.each do |record|
        box = { "ox" => 0, "oy" => 0, "alignment" => 0 }
        positions = upward_property_positions(
          record.merge(role: "member", box: box), heading: [-100, 0], style: record[:style], mult_box: box
        )

        expect(positions[record[:mult]]).to eq(record[:expected])
      end
    end

    it "seats leftward multiplicity on ends without a property stereotype from stored offsets" do
      records = [
        { anchor: [359, 135], mult: "0..*", box: { "ox" => -5, "oy" => 0, "alignment" => 1 }, expected: [337, 150] },
        { anchor: [417, 144], mult: "0..*", box: { "ox" => -8, "oy" => 4, "alignment" => 0 }, expected: [392, 163] }
      ]
      records.each do |record|
        positions = upward_property_positions(
          record.merge(role: "member"), heading: [-100, 0], style: { mode: "3", lwidth: "0" },
                                        mult_box: record[:box], stereotype: nil
        )

        expect(positions["0..*"]).to eq(record[:expected])
      end
    end

    it "seats leftward tree-route multiplicity like other leftward sources and keeps rightward tree defaults" do
      box = { "ox" => 0, "oy" => 0, "alignment" => 1 }
      record = { role: "member", anchor: [291, 521], mult: "0..*", box: box }
      style = { mode: "3", lwidth: "0", tree: "LV" }
      left = upward_property_positions(record, heading: [-30, 0], style: style, mult_box: box, tree: true)
      right = upward_property_positions(record, heading: [30, 0], style: style, mult_box: box, tree: true)

      expect(left["0..*"]).to eq([274, 536])
      expect(right["0..*"]).to eq([294, 521])
    end

    it "keeps the tree target multiplicity default whichever way its leg runs" do
      box = { "ox" => 0, "oy" => 0, "alignment" => 1 }
      record = { role: "member", anchor: [291, 521], mult: "0..*", box: box }
      [[-30, 0], [30, 0]].each do |heading|
        positions = upward_property_positions(record, heading: heading, end_kind: :target, style: { tree: "LV" },
                                                      mult_box: box, tree: true)

        expect(positions["0..*"]).to eq([299, 513])
      end
    end

    it "keeps the zero-box default for leftward multiplicity on other fonts" do
      box = { "ox" => 0, "oy" => 0, "alignment" => 0 }
      record = { role: "member", anchor: [649, 270], mult: "0..1", box: box }
      positions = upward_property_positions(record, heading: [-100, 0], style: { mode: "2", lwidth: "2" },
                                                    mult_box: box, family: "Carlito")

      expect(positions["0..1"]).to eq([661, 285])
    end

    it "seats downward multiplicities with property and plain association roles" do
      records = [
        { role: "interiorFurniture", anchor: [348, 508], mult: "0..*",
          box: { "ox" => 0, "oy" => 0, "alignment" => 1 },
          mult_box: { "ox" => 0, "oy" => 0, "alignment" => 1 }, expected: [356, 523] },
        { role: "interiorFurniture", anchor: [156, 610], mult: "0..*",
          box: { "ox" => 0, "oy" => 0, "alignment" => 1 },
          mult_box: { "ox" => 12, "oy" => -1, "alignment" => 1 }, expected: [176, 624] },
        { role: "role a", anchor: [72, 80], mult: "0..1", stereotype: nil,
          box: { "ox" => 0, "oy" => 0, "alignment" => 1 },
          mult_box: { "ox" => 0, "oy" => 2, "alignment" => 1 }, expected: [80, 97] }
      ]
      records.each do |record|
        positions = upward_property_positions(
          record, heading: [0, 100], mult_box: record[:mult_box],
                  stereotype: record.fetch(:stereotype, "property")
        )

        expect(positions[record[:mult]]).to eq(record[:expected])
        expect(positions["+#{record[:role]}"]).to eq(record[:anchor])
      end
    end

    it "preserves custom fonts and presentation for directional multiplicities" do
      [{ family: "Carlito" }, { size: 9 }, { mult_box: { "ox" => 4, "oy" => 5, "rotation" => 90 } }].each do |options|
        positions = upward_property_positions(
          traffic, heading: [0, 100], mult_box: { "ox" => 4, "oy" => 5 }, **options
        )

        expect(positions["0..1"]).to eq([195, 427])
      end
    end

    it "keeps alignment-zero property stereotypes left-aligned with the role" do
      records = [
        { role: "location", anchor: [765, 821],
          box: { "ox" => 17, "oy" => -27, "alignment" => 0 },
          heading: [0, -100], style: { mode: "3", lwidth: "2" }, expected: [682, 788] },
        { role: "tranFacilityIdAttribute", anchor: [801, 485],
          box: { "ox" => -14, "oy" => 32, "alignment" => 0 },
          heading: [-100, 0], style: { mode: "3", lwidth: "2", tree: "H" }, expected: [625, 510] }
      ]
      records.each do |record|
        positions = upward_property_positions(record, heading: record[:heading], style: record[:style])

        expect(positions["+#{record[:role]}"]).to eq(record[:expected])
        expect(positions["«property»"]).to eq([record[:expected][0], record[:expected][1] + 12])
      end
    end

    it "seats downward property roles on distinct direct layouts" do
      records = [
        { role: "interiorFurniture", anchor: [348, 508],
          box: { "ox" => 42, "oy" => 12, "alignment" => 1 },
          style: { mode: "3", lwidth: "2" }, expected: [244, 535] },
        { role: "lod0MultiPoint", anchor: [581, 117],
          box: { "ox" => 43, "oy" => 5, "alignment" => 1 },
          style: { mode: "3", lwidth: "2" }, expected: [487, 137] },
        { role: "threeDimensionalExtent", anchor: [303, 131],
          box: { "ox" => 267, "oy" => 3, "alignment" => 1 },
          style: { mode: "1", lwidth: "2" }, expected: [393, 149] }
      ]
      records.each do |record|
        positions = upward_property_positions(record, heading: [0, 100], style: record[:style])

        expect(positions["+#{record[:role]}"]).to eq(record[:expected])
      end
    end

    it "preserves unsupported downward role regimes" do
      [{ stereotype: nil }, { stereotype: "Type" }, { family: "Carlito" }, { size: 9 },
       { box: traffic[:box].merge("italic" => true) },
       { style: { mode: "3", lwidth: "0" } },
       { style: { mode: "3", lwidth: "2", tree: "V" } }].each do |options|
        positions = upward_property_positions(
          traffic, heading: [0, 100], style: { mode: "3", lwidth: "2" }, **options
        )

        expect(positions["+trafficVolumeAttribute"]).to eq([182, 434])
      end
    end

    it "preserves unproven presentation and routing regimes" do
      [{ stereotype: nil }, { stereotype: "Type" }, { family: "Carlito" },
       { box: traffic[:box].merge("alignment" => 0), stereotype: nil },
       { size: 9 }, { heading: nil }, { heading: [0, 100] },
       { box: traffic[:box].merge("rotation" => 90) },
       { box: traffic[:box].merge("bold" => true) },
       { style: { lwidth: "1" } }, { style: { lwidth: "2", tree: "OS" } }].each do |options|
        expect(upward_property_positions(traffic, **options)["+trafficVolumeAttribute"])
          .to eq([182, 434])
      end
    end

    it "seats upward property roles on the plain width-0 route like the width-2 route" do
      record = { role: "target", mult: "0..*", anchor: [347, 910],
                 box: { "ox" => 0, "oy" => 0, "alignment" => 0 } }
      positions = upward_property_positions(record, heading: [0, -1], style: { mode: "3", lwidth: "0" })

      expect(positions["+target"]).to eq([256, 904])
      expect(positions["«property»"]).to eq([256, 916])
    end

    it "moves a role cluster right until its left edge reaches x = 3" do
      records = [
        { role: "tunBaseAttribute", anchor: [120, 449], heading: [0, -60],
          box: { "ox" => 0, "oy" => -20, "alignment" => 1 }, expected: [[3, 423], [19, 435]] },
        { role: "bridBaseAttribute", anchor: [136, 299], heading: [0, -61],
          box: { "ox" => 0, "oy" => -26, "alignment" => 1 }, expected: [[3, 267], [20, 279]] }
      ]
      records.each do |record|
        positions = upward_property_positions(record, heading: record[:heading],
                                                      style: { mode: "3", lwidth: "2", tree: "V" })

        expect(positions["+#{record[:role]}"]).to eq(record[:expected][0])
        expect(positions["«property»"]).to eq(record[:expected][1])
      end
    end

    it "keeps negative role positions outside the measured upward Cambria 7pt cluster" do
      record = { role: "tunBaseAttribute", anchor: [120, 449],
                 box: { "ox" => -200, "oy" => 0, "alignment" => 1 } }
      controls = [{ family: "Carlito" }, { size: 9 }, { unit: "px" },
                  { box: record[:box].merge("rotation" => 90) },
                  { box: record[:box].merge("bold" => true) },
                  { heading: [-100, 0] }, { heading: nil }]
      controls.each do |options|
        positions = upward_property_positions(record, heading: [0, -60],
                                                      style: { mode: "3", lwidth: "2", tree: "V" }, **options)

        expect(positions["+tunBaseAttribute"][0]).to be_negative, options.inspect
      end
    end

    it "leaves a role cluster whose left edge is at or beyond x = 3 where it was" do
      # anchor 3 + 60 + 79 puts the left edge at exactly 3; one less would clamp.
      [[142, 3], [143, 4]].each do |anchor_x, expected_x|
        positions = upward_property_positions(
          { role: "tunBaseAttribute", anchor: [anchor_x, 449],
            box: { "ox" => 0, "oy" => -20, "alignment" => 1 } },
          heading: [0, -60], style: { mode: "3", lwidth: "2", tree: "V" }
        )

        expect(positions["+tunBaseAttribute"][0]).to eq(expected_x)
      end
    end

    it "seats a target role whose leg arrives from the right at its stored corner" do
      record = { role: "xalAddress", anchor: [876, 194], mult: nil,
                 box: { "ox" => 16, "oy" => -1, "alignment" => 1 } }
      positions = upward_property_positions(record, stereotype: "", end_kind: :target,
                                                    heading: [1, 0], style: { mode: "3", lwidth: "0" })

      expect(positions["+xalAddress"]).to eq([895, 186])
    end

    it "seats upward target property roles at their stored corners" do
      records = [
        { role: "referencePoint", anchor: [813, 700],
          box: { "ox" => 63, "oy" => -31, "alignment" => 1 }, expected: [741, 662] },
        { role: "relativeGMLGeometry", anchor: [620, 700],
          box: { "ox" => 60, "oy" => -22, "alignment" => 1 }, expected: [516, 671] }
      ]
      records.each do |record|
        positions = upward_property_positions(record, end_kind: :target, target_stereotype: "property",
                                                      style: { mode: "3", lwidth: "2" })

        expect(positions["+#{record[:role]}"]).to eq(record[:expected])
        expect(positions["«property»"][1]).to eq(record[:expected][1] + 12)
      end
    end

    it "centres a role narrower than the stereotype over it, keeping the stereotype edge" do
      # Plateau 159E9DA0/90BCA409 +endPoint (46 wide under the 48 wide stereotype)
      # sit one pixel right of the plain right-aligned seat; wider roles do not move.
      records = [
        { role: "endPoint", anchor: [210, 564], box: { "ox" => 64, "oy" => -35, "alignment" => 1 },
          expected: [164, 522], stereotype_x: 163 },
        { role: "startPoint", anchor: [225, 674], box: { "ox" => 42, "oy" => -32, "alignment" => 1 },
          expected: [154, 635], stereotype_x: 154 }
      ]
      records.each do |record|
        positions = upward_property_positions(record, end_kind: :target, target_stereotype: "property",
                                                      style: { mode: "3", lwidth: "2" })

        expect(positions["+#{record[:role]}"]).to eq(record[:expected])
        expect(positions["«property»"][0]).to eq(record[:stereotype_x])
      end
    end

    it "preserves unsupported upward target property presentations" do
      record = { role: "referencePoint", anchor: [813, 700],
                 box: { "ox" => 63, "oy" => -31, "alignment" => 1 } }
      controls = [{ family: "Carlito" }, { size: 9 }, { unit: "px" },
                  { target_stereotype: "Type" }, { heading: [1, -100] }, { heading: [0, 100] },
                  { style: { mode: "3", lwidth: "2", tree: "OS" } },
                  { box: record[:box].merge("bold" => true) },
                  { box: record[:box].merge("alignment" => 0) }]
      controls.each do |options|
        positions = upward_property_positions(record, end_kind: :target, target_stereotype: "property",
                                                      style: { mode: "3", lwidth: "2" }, **options)

        expect(positions["+referencePoint"]).to eq([876, 731])
      end
    end

    it "seats a target role whose leg runs down on the LV tree route" do
      record = { role: "lod0MultiPoint", anchor: [195, 441], mult: "1",
                 box: { "ox" => 0, "oy" => 0, "alignment" => 1 } }
      positions = upward_property_positions(
        record, stereotype: "", end_kind: :target, heading: [0, 86],
                style: { mode: "3", lwidth: "2", tree: "LV" }
      )

      expect(positions["+lod0MultiPoint"]).to eq([115, 456])
    end

    it "keeps downward target roles off other tree routes and unproven widths" do
      [{ mode: "3", lwidth: "2", tree: "V" }, { mode: "3", lwidth: "2" },
       { mode: "3", lwidth: "1", tree: "LV" }].each do |style|
        positions = upward_property_positions(
          { role: "lod0MultiPoint", anchor: [195, 441], box: { "ox" => 0, "oy" => 0, "alignment" => 1 } },
          stereotype: "", end_kind: :target, heading: [0, 86], style: style
        )

        expect(positions["+lod0MultiPoint"]).to eq([195, 441])
      end
    end

    it "preserves the existing rightward role seat" do
      expect(upward_property_positions(traffic, heading: [100, 0])["+trafficVolumeAttribute"])
        .to eq([185, 423])
    end

    it "preserves unproven leftward styles and non-property roles" do
      [{ style: { mode: "1", lwidth: "0" } }, { style: { mode: "3", lwidth: "0", tree: "V" } },
       { style: { lwidth: "0" }, stereotype: nil }].each do |options|
        positions = upward_property_positions(traffic, heading: [-100, 0], **options)

        expect(positions["+trafficVolumeAttribute"]).to eq([182, 434])
        expect(positions["0..1"]).to eq([182, 434])
      end
    end

    it "preserves unboxed roles and unsupported measured glyphs" do
      expect(upward_property_positions(traffic, box: nil)).not_to have_key("+trafficVolumeAttribute")
      traffic[:role] = "traffic☃"
      expect(upward_property_positions(traffic)["+traffic☃"]).to eq([182, 434])
    end
  end

  shared_context "stored end-label geometry" do
    let(:association) do
      Ea::Model::Association.new(
        id: "r1", source_id: "c1", target_id: "c2",
        source_multiplicity_raw: "0..*", target_multiplicity_raw: "0..*"
      )
    end
    let(:connector) do
      Ea::Model::DiagramConnector.new(id: "dc1", relationship_ref: association.id)
    end
    let(:label_cases) do
      [
        ["trafficVolumeAttribute", 94, 1, "property", 135],
        ["trafficVolumeAttributeX", 99, 1, "property", 138],
        ["target", 29, 1, "property", 102],
        ["trafficVolumeAttribute", 94, 0, "property", 110],
        ["trafficVolumeAttribute", 94, nil, "property", 110],
        ["trafficVolumeAttribute", 94, 2, "property", 110],
        ["trafficVolumeAttribute", 94, "1", "property", 110],
        ["trafficVolumeAttribute", 94, "unknown", "property", 110],
        ["trafficVolumeAttribute", 94, :absent, "property", 110],
        ["trafficVolumeAttribute", 94, 1, nil, nil]
      ]
    end
  end

  shared_examples "stored end-label alignment" do
    it "centers only explicitly aligned stereotypes while preserving the rest of the cluster" do
      label_cases.each do |role_name, role_length, alignment, stereotype, stereotype_x|
        association.source_role_name = association.target_role_name = role_name
        connector.source_stereotype = connector.target_stereotype = stereotype
        box = { "ox" => 10, "oy" => 15 }
        box.merge!("cx" => 93, "cy" => 13, "alignment" => alignment) unless alignment == :absent
        texts = renderer.texts(text_box: box,
                               mult_box: { "ox" => 30, "oy" => 5 },
                               anchor: [100, 200], connector:, end_kind:)
        parsed = texts.map { |text| Nokogiri::XML(text).at_css("text") }

        expect(parsed.map(&:text)).to eq(
          ["+#{role_name}", stereotype && "«#{stereotype}»", "0..*"].compact
        )
        expect(parsed.map { |text| text["textLength"].to_i }).to eq(
          [role_length, stereotype && 44, 16].compact
        )
        # Default presentation sits 12px below the role on 7pt labels
        # (reference clusters); custom alignment keeps size + 6.
        stereotype_y = [2, "1", "unknown"].include?(alignment) ? 198 : 197
        expect(parsed.map { |text| [text["x"].to_f, text["y"].to_f] }).to eq(
          [[110, 185], stereotype && [stereotype_x, stereotype_y],
           [130, 195]].compact
        )
      end
    end
  end

  %i[source target].each do |end_kind|
    context "with stored label geometry at the #{end_kind} end" do
      include_context "stored end-label geometry"
      let(:end_kind) { end_kind }

      include_examples "stored end-label alignment"
    end
  end
end
