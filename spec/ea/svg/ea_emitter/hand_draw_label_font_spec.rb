# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::Labels, "font family on hand-drawn diagrams" do
  let(:source_property) do
    Ea::Model::Property.new(id: "p_src", name: "items", owner_id: "c1",
                            visibility: "public", multiplicity_lower: 0,
                            multiplicity_upper: -1)
  end
  let(:target_property) do
    Ea::Model::Property.new(id: "p_tgt", name: "owner", owner_id: "c2",
                            visibility: "public", multiplicity_lower: 0,
                            multiplicity_upper: 1)
  end
  let(:relationship) do
    Ea::Model::Association.new(id: "r1", name: "Relationship One", source_id: "p_src",
                               target_id: "p_tgt")
  end
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
  let(:hand_draw) { true }
  let(:document) do
    Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      classifiers: [
        Ea::Model::Klass.new(id: "c1", name: "A", properties: [source_property]),
        Ea::Model::Klass.new(id: "c2", name: "B", properties: [target_property])
      ],
      relationships: [relationship],
      diagrams: [Ea::Model::Diagram.new(id: "d1", name: "D", hand_draw: hand_draw,
                                        connectors: [connector])]
    )
  end
  let(:diagram) { document.diagrams.first }
  let(:styles) do
    svg = described_class.new(diagram, model_index: document.index_by_id, theme: theme).render
    Nokogiri::XML("<svg>#{svg}</svg>").css("text").map { |n| n["style"] }
  end
  let(:families) { styles.map { |style| style[/font-family:([^;]*);/, 1] } }
  let(:theme) { Ea::Theme::Definition.new(id: "labels", font_family: "Carlito", label_font_family: "Cambria", font_size: 7) }

  it "draws role and multiplicity labels in the hand-drawn family" do
    expect(families).not_to be_empty
    expect(families.uniq).to eq(["Source Sans Pro"])
  end

  it "includes the connector name label" do
    svg = described_class.new(diagram, model_index: document.index_by_id, theme: theme).render
    expect(svg).to include("Relationship One")
  end

  it "draws them italic with weight 0" do
    expect(styles).to all(include("font-weight:0;", "font-style:italic;"))
  end

  context "when the diagram is not hand-drawn" do
    let(:hand_draw) { false }

    it "keeps normal style and weight 400" do
      expect(styles).to all(include("font-weight:400;", "font-style:normal;"))
    end

    it "keeps the theme label family" do
      expect(families.uniq).to eq(["Cambria"])
    end
  end
end
