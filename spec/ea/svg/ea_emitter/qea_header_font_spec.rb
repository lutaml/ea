# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe "QEA Cambria header widths" do
  include QeaCompartmentFontHelpers

  let(:document) { public_compartment_document }

  it "centers bold headers using native seven point Cambria advances" do
    texts = compartment_texts(document, "0114FD24-9E58-4664-98CD-71305B59AD11")
    {
      "uro::OtherConstruction" => [829, 94, 112],
      "uro::EmbankmentAttribute" => [92, 944, 129],
      "uro::DataQualityAttribute" => [426, 377, 121],
      "uro::FacilityIdAttribute" => [704, 361, 111]
    }.each do |name, expected|
      row = texts.find { |node| node.text == name }

      expect([row["x"].to_f + 3, row["y"].to_f + 2, row["textLength"].to_i]).to eq(expected)
    end
  end
end
