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
        expect(parsed.map { |text| [text["x"].to_f, text["y"].to_f] }).to eq(
          [[110, 185], stereotype && [stereotype_x, 198], [130, 195]].compact
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

  # Stored boxes of a source end whose first leg leaves up or right.
  # Up-leg values are connector dc:176:861 of reference EAID_04EE9625
  # (tunKeyValuePairAttribute, Aggregation, «property» source end).
  describe "source-end leg seats" do
    let(:association) do
      Ea::Model::Association.new(
        id: "r1", source_id: "c1", target_id: "c2",
        source_role_name: "tunKeyValuePairAttribute",
        source_multiplicity_raw: "0..*"
      )
    end
    let(:connector) do
      Ea::Model::DiagramConnector.new(id: "dc:176:861",
                                      relationship_ref: association.id,
                                      source_stereotype: stereotype)
    end
    let(:stereotype) { "property" }
    let(:role) { "+tunKeyValuePairAttribute" }
    let(:text_box) { { "ox" => 44, "oy" => -20 } }
    let(:mult_box) { { "ox" => 12, "oy" => -1 } }

    def seats(anchor:, heading:, end_kind: :source, text_box: self.text_box,
              mult_box: self.mult_box)
      texts = renderer.texts(text_box:, mult_box:, anchor:,
                             connector:, end_kind:, heading:)
      texts.to_h do |text|
        node = Nokogiri::XML(text).at_css("text")
        [node.text, [node["x"].to_f, node["y"].to_f]]
      end
    end

    def role_width
      Ea::Svg::EaEmitter::TextRenderer.estimate_width(
        role, 7, family: "Carlito"
      ).round
    end

    it "seats an upward leg's role right-aligned and its multiplicity above the corner" do
      placed = seats(anchor: [1441, 466], heading: [0, -218])

      expect(placed["0..*"]).to eq([1456, 459])
      expect(placed[role][1]).to eq(440)
      expect(placed[role][0] + role_width).to eq(1441 + 44 - 60)
    end

    it "ends the role 3px before the corner when no stereotype line follows" do
      connector.source_stereotype = nil
      placed = seats(anchor: [1441, 466], heading: [0, -218])

      expect(placed[role][0] + role_width).to eq(1441 + 44 - 3)
      expect(placed[role][1]).to eq(440)
    end

    it "seats a rightward leg's role and multiplicity beside the corner" do
      placed = seats(anchor: [452, 255], heading: [283, 0],
                     text_box: { "ox" => 46, "oy" => -16 },
                     mult_box: { "ox" => 8, "oy" => 3 })

      expect(placed[role]).to eq([501, 232])
      expect(placed["0..*"]).to eq([463, 273])
    end

    [
      ["a downward leg", { heading: [0, 40] }],
      ["a leftward leg", { heading: [-40, 0] }],
      ["a diagonal leg", { heading: [40, -40] }],
      ["no known leg", { heading: nil }],
      ["the target end", { heading: [0, -40], end_kind: :target }]
    ].each do |name, options|
      it "keeps the plain offset for #{name}" do
        placed = seats(anchor: [100, 200], **options)

        expect(placed[role][1]).to eq(200 + 20)
        expect(placed[role][0]).to eq(100 + 44)
        expect(placed["0..*"]).to eq([112, 201])
      end
    end

    it "keeps the default multiplicity seat for a zero multiplicity box" do
      placed = seats(anchor: [100, 200], heading: [0, -40],
                     mult_box: { "ox" => 0, "oy" => 0 })

      expect(placed["0..*"]).to eq([112, 215])
      expect(placed[role][1]).to eq(200 - 20 - 6)
    end
  end
end
