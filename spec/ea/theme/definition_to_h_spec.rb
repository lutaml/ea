# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Theme::Definition, "#to_h" do
  let(:definition) do
    described_class.new(
      id: "119", name: "EA White Theme",
      font_family: "Carlito", font_size: 7, font_size_unit: "pt",
      text_color: "#000000", text_weight_normal: 400, text_weight_bold: 700,
      border_color: "#9A8484", element_border_width: 2,
      fills: { "Ea::Model::Klass" => "#FDFAF7" }
    )
  end

  it "returns a Hash with all fields" do
    h = definition.to_h
    expect(h[:id]).to eq("119")
    expect(h[:name]).to eq("EA White Theme")
    expect(h[:font_family]).to eq("Carlito")
    expect(h[:font_size]).to eq(7)
    expect(h[:font_size_unit]).to eq("pt")
    expect(h[:text_color]).to eq("#000000")
    expect(h[:text_weight_normal]).to eq(400)
    expect(h[:text_weight_bold]).to eq(700)
    expect(h[:border_color]).to eq("#9A8484")
    expect(h[:element_border_width]).to eq(2)
    expect(h[:fills]["Ea::Model::Klass"]).to eq("#FDFAF7")
  end

  it "round-trips through to_h and Definition.new" do
    h = definition.to_h
    restored = described_class.new(**h)
    expect(restored.id).to eq("119")
    expect(restored.font_family).to eq("Carlito")
    expect(restored.text_color).to eq("#000000")
    expect(restored.element_border_width).to eq(2)
  end
end
