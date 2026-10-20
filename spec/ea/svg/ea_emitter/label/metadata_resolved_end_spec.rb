# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Svg::EaEmitter::Label::EndLabel, "metadata-resolved parent end" do
  include Issue135OppositeEndHelpers

  it "keeps metadata-resolved parent labels at their named end without stored boxes" do
    document = opposite_end_document(source_role: "parent")
    document.property_by_id("member").name = "parent"
    style = { explicit_end_roles: true }

    expect(opposite_end_texts(document, :source, stored_labels: false, style: style))
      .to eq(["+parent", "«property»", "0..1"])
    expect(opposite_end_texts(document, :target, stored_labels: false, style: style)).to be_empty
  end
end
