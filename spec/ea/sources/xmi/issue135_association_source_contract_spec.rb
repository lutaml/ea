# frozen_string_literal: true

require "spec_helper"
require "xmi"
require "nokogiri"

RSpec.describe Ea::Sources::Xmi::Adapter, "issue 135 association source contract" do
  include Issue135AssociationSourceContractHelpers

  let(:document) { described_class.from_path(fixtures_path("basic.xmi")) }

  it "renders F32E5AFE using saved roles and multiplicities while preserving ordinary attributes" do
    texts = issue135_source_texts(document, "F32E5AFE")

    expect(texts).to include("+roleThree", "0..3", "+roleTwo", "+roleOne")
    expect(texts.count("1")).to eq(2)
    expect(texts).not_to include("+: Classes::Class B")
    expect(texts.count("attributeOne: typeOne")).to eq(3)
    expect(texts.count("attributeTwo: typeTwo")).to eq(3)
    expect(texts.count("attributeThree: typeThree")).to eq(2)
    klass = issue135_source_class_c(document)
    expect(klass.properties.map(&:name)).to eq(["attributeOne", "attributeTwo", "attributeThree", nil])
  end

  it "renders 6D0349D5 using the saved role b and unbounded multiplicity" do
    texts = issue135_source_texts(document, "6D0349D5")

    expect(texts).to include("+role b", "0..*", "1")
    expect(texts.grep(/^\+:/)).to be_empty
  end

  it "renders both E325B9D8 association multiplicities from their saved ends" do
    texts = issue135_source_texts(document, "E325B9D8")

    expect(texts).to include("Relationship One", "Relationship Two")
    expect(texts.count("0..*")).to eq(2)
    expect(texts.count("1")).to eq(2)
  end
end

RSpec.describe Ea::Sources::Xmi::Adapter, "issue 135 named association preservation" do
  include Issue135AssociationSourceContractHelpers

  it "preserves named typed association properties, their labels, and unnamed ordinary attributes" do
    named_document = issue135_named_source_document
    klass = issue135_source_class_c(named_document)
    property = klass.properties.find { |item| item.name == "typedBoundary" }

    expect(property).to have_attributes(
      association_id: "EAID_B3CF64D9_3CAA_41e2_862C_8C4A9BA09AC2",
      visibility: "public", type_name: "Classes::Class B",
      multiplicity_lower: 0, multiplicity_upper: -1
    )
    expect(klass.properties.map(&:id)).to include("unnamed-ordinary-attribute")
    diagram = named_document.diagrams.find { |item| item.id.start_with?("EAID_F32E5AFE") }
    connector = diagram.connectors.find { |item| item.relationship_ref == property.association_id }
    connector.source_stereotype = "Property"
    texts = issue135_source_texts(named_document, "F32E5AFE")

    expect(texts).to include("+typedBoundary: Classes::Class B", "0..*", "«Property»")
  end

  it "retains empty-name association references and unnamed ordinary attributes in the source model" do
    klass = issue135_source_class_c(issue135_named_source_document)

    expect(klass.properties.map(&:id)).to include("unnamed-ordinary-attribute", "empty-association-end")
  end
end

RSpec.describe Ea::Sources::Xmi::Adapter, "issue 135 member-end property references" do
  include Issue135AssociationSourceContractHelpers

  it "keeps unnamed property endpoints resolvable without an EA connector extension" do
    document = issue135_generic_source_document
    association = document.relationships.find { |item| item.id == "EAID_B3CF64D9_3CAA_41e2_862C_8C4A9BA09AC2" }

    expect(document.property_by_id(association.source_id)).to have_attributes(
      name: nil, type_name: "Classes::Class B", multiplicity_lower: 1, multiplicity_upper: 1
    )
    expect(issue135_source_endpoint_texts(document, association)).to include("+: Classes::Class B", "1")
  end
end
