# frozen_string_literal: true

require "spec_helper"

RSpec.describe "XMI standard profile stereotype display" do
  include XmiStereotypeProfileHelpers

  it "renders the saved standard profile Type as lowercase without changing its semantic name" do
    document = xmi_stereotype_document("Type", "StandardProfileL2::Type")

    expect(xmi_profile_result(document)).to eq([["Type"], ["«type»"]])
  end

  it "finds matching provenance after an unrelated packed stereotype application" do
    prefix = "$XREFPROP=$DES=@STEREO;Name=Other;FQName=Custom::Other;@ENDSTEREO;$ENDXREF;"
    document = xmi_stereotype_document("Type", "StandardProfileL2::Type", prefix: prefix)

    expect(xmi_profile_result(document)).to eq([["Type"], ["«type»"]])
  end

  it "preserves custom profiles, case and names without matching saved provenance" do
    [
      ["Type", "GML::Type", "Type"],
      ["Type", "standardprofilel2::Type", "Type"],
      ["TYPE", "StandardProfileL2::TYPE", "TYPE"],
      ["type", "StandardProfileL2::type", "type"],
      ["Type", nil, "Type"],
      ["ImplementationClass", "StandardProfileL2::ImplementationClass", "ImplementationClass"],
      ["CustomType", "StandardProfileL2::Type", "Type"],
      ["Type", "StandardProfileL2::Type", "CustomType"]
    ].each do |name, fqname, application_name|
      document = xmi_stereotype_document(name, fqname, application_name: application_name)

      expect(xmi_profile_result(document)).to eq([[name], ["«#{name}»"]])
    end
  end
end

RSpec.describe "XMI profiled UMLDI keyword display" do
  include XmiStereotypeProfileHelpers

  it "canonicalizes the standard Type when the saved UMLDI keyword takes precedence" do
    document = xmi_stereotype_document("Type", "StandardProfileL2::Type", keyword: "Type")

    expect(xmi_profile_result(document)).to eq([["Type"], ["«type»"]])
  end

  it "preserves custom, unprofiled and unrelated UMLDI keywords" do
    [
      ["GML::Type", "Type"],
      [nil, "Type"],
      ["StandardProfileL2::Type", "Other"]
    ].each do |fqname, keyword|
      document = xmi_stereotype_document("Type", fqname, keyword: keyword)

      expect(xmi_profile_result(document)).to eq([["Type"], ["«#{keyword}»"]])
    end
  end
end

RSpec.describe "XMI multiple UMLDI keyword display" do
  include XmiStereotypeProfileHelpers

  it "selects the saved custom stereotype over the built-in enumeration keyword" do
    document = xmi_stereotype_document("Enumeration", "GML::Enumeration",
                                       keyword: %w[enumeration Enumeration])

    expect(xmi_profile_result(document)).to eq([["Enumeration"], ["«Enumeration»"]])
  end

  it "preserves the first keyword when none matches the saved stereotype" do
    document = xmi_stereotype_document("Other", "Custom::Other",
                                       keyword: %w[enumeration Enumeration])

    expect(xmi_profile_result(document)).to eq([["Other"], ["«enumeration»"]])
  end

  it "keeps matching selection independent of keyword order" do
    document = xmi_stereotype_document("Enumeration", "GML::Enumeration",
                                       keyword: %w[Enumeration enumeration])

    expect(xmi_profile_result(document)).to eq([["Enumeration"], ["«Enumeration»"]])
  end

  it "preserves a sole built-in keyword without synthesizing a custom label" do
    document = xmi_stereotype_document("Enumeration", "GML::Enumeration", keyword: "enumeration")

    expect(xmi_profile_result(document)).to eq([["Enumeration"], ["«enumeration»"]])
  end
end
