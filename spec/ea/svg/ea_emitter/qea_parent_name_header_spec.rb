# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe "QEA parent-to-name header spacing" do
  include QeaCompartmentFontHelpers

  let(:document) { public_compartment_document }

  it "separates the Cambria parent ghost from an unwrapped abstract name by 15 pixels" do
    texts = compartment_texts(document, "09927B7F-A657-4819-99E5-AC9DC99227D9")
    ghost = texts.find { |text| text.text == "_CityObject" }
    name = texts.find { |text| text.text == "tran::_TransportationObject" }

    expect(name["y"].to_f - ghost["y"].to_f).to eq(15)
    expect([ghost["textLength"], name["textLength"]]).to eq(%w[46 132])
  end

  it "separates the Carlito parent ghost from a wrapped abstract name by 18 pixels" do
    texts = compartment_texts(document, "9BD7189A-877B-4ca9-B42C-817DEF144FB2")
    ghost = texts.find { |text| text.text == "_CityObject" }
    names = %w[tran:: _TransportationObject].map do |content|
      texts.find { |text| text.text == content }
    end

    expect(names.map { |text| text["y"].to_f - ghost["y"].to_f }).to eq([18, 33])
    expect(names.map { |text| text["textLength"] }).to eq(%w[32 124])
  end

  it "preserves ordinary wrapped abstract names without a parent ghost" do
    texts = compartment_texts(document, "A282E5D1-2A13-4e7f-BC76-5D086DD4A577")
    names = %w[tran:: _TransportationObject].map do |content|
      texts.find { |text| text.text == content }
    end

    expect(names.last["y"].to_f - names.first["y"].to_f).to eq(15)
  end
end
