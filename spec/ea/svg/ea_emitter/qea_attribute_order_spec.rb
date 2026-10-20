# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA attribute display ordering" do
  include TestDatabaseHelper
  include QeaAttributeOrderHelpers

  it "renders the source Pos order through the public QEA document pipeline" do
    document = qea_attribute_order_document([["alpha", 2], ["zulu", 0], ["middle", 1]])
    expect(rendered_attribute_names(document)).to eq(["zulu: String", "middle: String", "alpha: String"])
  end

  it "keeps missing positions stable and preserves property IDs" do
    document = qea_attribute_order_document([["zulu", nil], ["middle", nil], ["alpha", nil]])
    expect(rendered_attribute_names(document)).to eq(["zulu: String", "middle: String", "alpha: String"])
    expect(document.index_by_id.fetch("class").properties.map(&:id)).to eq(%w[a0 a1 a2])
  end

  it "breaks duplicate explicit Pos ties alphabetically as the reference rows do" do
    document = qea_attribute_order_document([["totalCost", 26], ["mainMaterial", 26], ["note", 28]])
    expect(rendered_attribute_names(document)).to eq(["mainMaterial: String", "totalCost: String", "note: String"])
  end

  it "preserves stored ordering below a shared stereotype header" do
    document = qea_attribute_order_document([["alpha", 1], ["zulu", 0]], stereotype: "Property")
    expect(rendered_attribute_names(document)).to eq(["zulu: String", "alpha: String"])
  end

  it "retains alphabetical rendering without the QEA provenance flag" do
    document = qea_attribute_order_document([["zulu", 0], ["alpha", 1]])
    document.diagrams.first.elements.first.style.delete(:stored_attribute_order)
    expect(rendered_attribute_names(document)).to eq(["alpha: String", "zulu: String"])
  end

  it "excludes undrawn association ends while preserving source attribute order" do
    document = qea_attribute_order_document([["zulu", 0], ["alpha", 1]])
    classifier = document.index_by_id.fetch("class")
    classifier.properties += [
      Ea::Model::Property.new(id: "end-z", name: "zEnd", type_name: "String", association_id: "rel"),
      Ea::Model::Property.new(id: "end-a", name: "aEnd", type_name: "String", association_id: "rel")
    ]
    lines = Ea::Svg::EaEmitter::Element::AttributeRenderer.lines_for(
      classifier, exclude_association_ids: [], stored_order: true
    )
    expect(lines).to eq(["+ zulu: String", "+ alpha: String"])
  end
end
