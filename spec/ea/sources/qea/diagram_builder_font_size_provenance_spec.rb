# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA effective font size provenance" do
  include QeaFontSizeProvenanceHelpers

  it "records default inheritance for absent, empty and zero saved sizes" do
    [nil, "fontsz=;", "fontsz=0;"].each do |style|
      element = font_provenance_element(placement: style)

      expect(element.font_size_inherited).to be(true)
      expect(element.font_size).to be_nil
    end
  end

  it "preserves effective classifier sizes behind placement defaults" do
    [nil, "fontsz=;", "fontsz=0;"].each do |style|
      element = font_provenance_element(placement: style, classifier: "font=Arial;fontsz=100;")

      expect(element.font_size_inherited).to be(false)
      expect([element.font_family, element.font_size, element.font_logical_height]).to eq(["Arial", 9, 13])
    end
  end

  it "keeps explicit placement sizes ahead of classifier defaults" do
    element = font_provenance_element(placement: "font=Calibri;fontsz=90;", classifier: "fontsz=100;")

    expect(element.font_size_inherited).to be(false)
    expect([element.font_family, element.font_size, element.font_logical_height]).to eq(["Calibri", 9, 12])
  end
end
