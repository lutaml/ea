# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::Labels, "font family on hand-drawn diagrams" do
  include HandDrawLabelFontHelpers

  let(:hand_draw) { true }
  let(:document) { hand_draw_label_document(hand_draw: hand_draw) }
  let(:diagram) { document.diagrams.first }
  let(:styles) { hand_draw_label_styles(document, theme: theme) }
  let(:families) { styles.map { |style| style[/font-family:([^;]*);/, 1] } }
  let(:theme) { Ea::Theme::Definition.new(id: "labels", font_family: "Carlito", label_font_family: "Cambria", font_size: 7) }

  it "draws role and multiplicity labels in the hand-drawn family" do
    expect(families).not_to be_empty
    expect(families.uniq).to eq(["Source Sans Pro"])

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
