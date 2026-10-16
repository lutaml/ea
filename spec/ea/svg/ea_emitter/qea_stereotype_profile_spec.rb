# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA standard profile stereotype display" do
  include QeaStereotypeProfileHelpers
  include QeaContentHelpers

  it "uses EA's graphical type spelling while preserving the semantic Type name" do
    document = qea_stereotype_profile_document("Type", "StandardProfileL2::Type")

    expect(document.classifiers.first.stereotype_refs).to eq(["Type"])
    expect(qea_texts(document, "diagram")).to include("«type»")
    expect(qea_texts(document, "diagram")).not_to include("«Type»")
  end

  it "preserves other profiles, custom names, and stereotypes without matching provenance" do
    [
      ["Type", "GML::Type", "Type"],
      ["Type", "Unknown::Type", "Type"],
      ["Type", "standardprofilel2::Type", "Type"],
      ["TYPE", "StandardProfileL2::TYPE", "TYPE"],
      ["type", "StandardProfileL2::type", "type"],
      ["Type", nil, "Type"],
      ["ImplementationClass", "StandardProfileL2::ImplementationClass", "ImplementationClass"],
      ["CustomType", "StandardProfileL2::Type", "Type"],
      ["Type", "StandardProfileL2::Type", "CustomType"]
    ].each do |name, fqname, application_name|
      document = qea_stereotype_profile_document(name, fqname, application_name: application_name)

      expect(document.classifiers.first.stereotype_refs).to eq([name])
      expect(qea_texts(document, "diagram").grep(/«/)).to eq(["«#{name}»"])
    end
  end
end
