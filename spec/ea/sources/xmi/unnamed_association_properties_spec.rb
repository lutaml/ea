# frozen_string_literal: true

require "spec_helper"
require "nokogiri"
require "xmi"

RSpec.describe Ea::Sources::Xmi::PropertyBuilder, "unnamed association ends" do
  include XmiUnnamedAssociationHelpers

  let(:document) { Ea::Sources::Xmi::Adapter.from_path(fixtures_path("basic.xmi")) }

  it "omits the unnamed opposite-end property from Class C" do
    properties = document.classifiers.flat_map(&:properties)

    expect(properties.map(&:id)).not_to include("EAID_dstCF64D9_3CAA_41e2_862C_8C4A9BA09AC2")
  end

  it "uses the saved role and cardinality instead of the unnamed property" do
    texts = unnamed_association_texts(document, "F32E5AFE")

    expect(texts).to include("+roleThree", "0..3", "+roleTwo", "+roleOne")
    expect(texts).not_to include("+: Classes::Class B")
  end

  it "keeps both unbounded multiplicities and relationship names" do
    texts = unnamed_association_texts(document, "E325B9D8")

    expect(texts.count("0..*")).to eq(2)
    expect(texts.count("1")).to eq(2)
    expect(texts).to include("Relationship Two", "Relationship One")
  end
end

RSpec.describe Ea::Sources::Xmi::PropertyBuilder, "preserved properties" do
  include XmiUnnamedAssociationHelpers

  let(:document) { Ea::Sources::Xmi::Adapter.from_path(fixtures_path("basic.xmi")) }

  it "keeps ordinary attribute rows" do
    expect(unnamed_association_texts(document, "4F421236")).to include("Attribute A: int", "Attribute B: int")
  end

  it "keeps named association properties in typed connector labels" do
    texts = unnamed_association_texts(named_association_document, "F32E5AFE")

    expect(texts).to include("+retained: Classes::Class B")
  end

  it "retains a named association property and its resolved type" do
    properties = named_association_document.classifiers.flat_map(&:properties)
    property = properties.find { |item| item.id == "EAID_dstCF64D9_3CAA_41e2_862C_8C4A9BA09AC2" }

    expect(property).to have_attributes(
      name: "retained", type_name: "Classes::Class B",
      association_id: "EAID_B3CF64D9_3CAA_41e2_862C_8C4A9BA09AC2",
      multiplicity_lower: 1, multiplicity_upper: 1
    )
  end
end
