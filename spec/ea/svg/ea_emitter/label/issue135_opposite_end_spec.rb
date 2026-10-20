# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Svg::EaEmitter::Label::EndLabel, "0F413534 opposite association end" do
  include Issue135OppositeEndHelpers

  it "renders lod0MultiSurface only at the saved named end without deleting its UML property" do
    document = opposite_end_document

    expect(opposite_end_texts(document, :source)).to eq(["+lod0MultiSurface", "«property»", "0..1"])
    expect(opposite_end_texts(document, :target)).to be_empty
    expect(document.property_by_id("member")).to have_attributes(
      name: "lod0MultiSurface", owner_id: "urban", type_name: "gml::MultiSurface"
    )
  end

  it "preserves a typed property at an independently named opposite end" do
    document = opposite_end_document(target_role: "lod0MultiSurface")

    expect(opposite_end_texts(document, :target)).to eq(["+lod0MultiSurface: gml::MultiSurface", "0..1"])
    expect(opposite_end_texts(document, :source)).to include("+lod0MultiSurface")
  end

  it "preserves typed properties when neither endpoint supplies a saved role" do
    document = opposite_end_document(source_role: nil)

    expect(opposite_end_texts(document, :target)).to eq(["+lod0MultiSurface: gml::MultiSurface", "0..1"])
  end

  it "falls back to the saved opposite role when no stored labels exist" do
    document = opposite_end_document

    expect(opposite_end_texts(document, :target, stored_labels: false)).to eq(["+lod0MultiSurface", "0..1"])
  end
end
