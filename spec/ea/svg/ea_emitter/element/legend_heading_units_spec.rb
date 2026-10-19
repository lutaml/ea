# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Legend heading font units" do
  include QeaCompartmentFontHelpers

  let(:document) { public_compartment_document }

  it "converts the saved pixel heading size to the native point size" do
    {
      "00C5C772-5A03-434f-BF30-AC37542A1AAC" => 7,
      "09AF6B8A-557C-43bc-BBB0-47C1E9401EF3" => 9
    }.each do |id, item_size|
      texts = compartment_texts(document, id)
      title = texts.find { |node| node.text == "凡例" }
      labels = texts.select { |node| node.text.include?("で定義されたクラス") }

      expect(title["style"]).to include("font-size:12pt")
      expect(labels.size).to eq(3)
      expect(labels.map { |node| node["style"] }).to all(include("font-size:#{item_size}pt"))
    end
  end

  it "preserves the default heading size and the item baselines" do
    texts = compartment_texts(document, "0016F797-D055-4717-AF1A-606413D0A166")
    title = texts.find { |node| node.text == "凡例" }
    labels = texts.select { |node| node.text.include?("に定義されたクラス") }

    expect(title["style"]).to include("font-size:12pt")
    expect(labels.map { |node| node["y"].to_f - title["y"].to_f }).to eq([22, 41, 60])
    expect(labels.map { |node| node["style"] }).to all(include("font-size:9pt"))
  end
end
