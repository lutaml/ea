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
       { box: traffic[:box].merge("alignment" => 0) },
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
       { style: { lwidth: "0" } }, { style: { lwidth: "2", tree: "OS" } }].each do |options|
        expect(upward_property_positions(traffic, **options)["+trafficVolumeAttribute"])
          .to eq([182, 434])
      end
    end

    it "preserves the existing rightward role seat" do
      expect(upward_property_positions(traffic, heading: [100, 0])["+trafficVolumeAttribute"])
        .to eq([185, 423])
    end

    it "preserves unproven leftward styles and non-property roles" do
      [{ style: { mode: "1", lwidth: "2" } }, { style: { mode: "3", lwidth: "0", tree: "V" } },
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
