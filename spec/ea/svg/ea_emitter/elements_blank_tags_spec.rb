# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Svg::EaEmitter::Elements do
  include BlankTagHelpers

  let(:values) { { "VCSWKID" => nil, "Empty" => "", "WKID" => "0", "HighPrecision" => "false" } }

  it "omits ArcGIS 7C44AC09 null QEA tags while retaining populated tags and the source model" do
    document = qea_tag_document(values)
    expect(document.diagrams.first.elements.first.show_tagged_values).to be(true)
    before = document.classifiers.first.tagged_values.map { |tag| [tag.key, tag.value] }
    expect(tag_svg(document).css("text").map(&:text)).to eq(
      ["Spatial References", "tags", "WKID = 0", "HighPrecision = false"]
    )
    expect(document.classifiers.first.tagged_values.map { |tag| [tag.key, tag.value] }).to eq(before)
    expect(before).to eq(values.to_a)
  end

  it "omits missing and empty XMI tag values while preserving populated values" do
    document = xmi_tag_document
    expect(document.diagrams.first.elements.first.show_tagged_values).to be(true)
    tags = document.classifiers.first.tagged_values.map { |tag| [tag.key, tag.value] }
    expect(tags).to eq([["VCSWKID", nil], ["Empty", nil], %w[WKID 0], %w[HighPrecision false]])
    expect(tag_svg(document).css("text").map(&:text)).to eq(
      ["Spatial References", "tags", "WKID = 0", "HighPrecision = false"]
    )
  end

  it "leaves a blank-only compartment with the same geometry as no tags" do
    blank = qea_tag_document("VCSWKID" => nil, "Empty" => "")
    expect(tag_svg(blank).to_xml).to eq(tag_svg(qea_tag_document({})).to_xml)
  end
end

RSpec.describe Ea::Svg::EaEmitter::Elements, "tag preservation" do
  include BlankTagHelpers

  let(:values) { { "VCSWKID" => nil, "Empty" => "", "WKID" => "0", "HighPrecision" => "false" } }

  it "retains whitespace, numeric zero and boolean false values" do
    document = qea_tag_document("Space" => " ", "Zero" => 0, "False" => false)
    expect(tag_svg(document).css("text").map(&:text)).to eq(
      ["Spatial References", "tags", "Space =  ", "Zero = 0", "False = false"]
    )
  end

  it "keeps populated tags hidden when the compartment is disabled" do
    expect(tag_svg(qea_tag_document(values), visible: false).css("text").map(&:text)).to eq(["Spatial References"])
  end
end
