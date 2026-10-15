# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "ea"

RSpec.describe Ea::Theme::Definition do
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

  it "loads Cambria for EA119 labels while keeping diagram fonts" do
    path = File.expand_path("../../../config/themes/119.yml", __dir__)
    theme = Ea::Theme::Loader.load_file(path)

    expect(theme.label_font_family).to eq("Cambria")
    expect(theme.font_family).to eq("Carlito")
    expect(theme.font_size).to eq(7)
    expect(theme.element_font_size).to eq(9)
  end

  it "loads custom theme fonts without requiring a label font" do
    Tempfile.create(["custom-theme", ".yml"]) do |file|
      file.write("id: custom\nfont:\n  family: Helvetica\n")
      file.flush
      theme = Ea::Theme::Loader.load_file(file.path)

      expect(theme.font_family).to eq("Helvetica")
      expect(theme.label_font_family).to eq("Helvetica")
    end
  end

  it "uses the diagram family when no label family is configured" do
    expect(definition.label_font_family).to eq("Carlito")
    expect(described_class.new(id: "default").label_font_family).to be_nil
    expect(definition.with(font_family: "Helvetica").label_font_family)
      .to eq("Helvetica")
  end

  it "preserves the label family through unrelated changes and serialization" do
    labeled = definition.with(label_font_family: "Cambria")
    restored = described_class.new(**labeled.to_h)

    expect(restored.with(text_color: "#112233").label_font_family)
      .to eq("Cambria")
    expect(restored.font_family).to eq("Carlito")
  end

  it "lets a global family override replace inherited label fonts" do
    labeled = definition.with(label_font_family: "Cambria")

    expect(labeled.with(font_family: "Helvetica").label_font_family)
      .to eq("Helvetica")
    expect(labeled.with(font_family: nil).label_font_family).to be_nil
    expect(labeled.label_font_family).to eq("Cambria")
  end

  it "honors an explicit label family together with a global override" do
    labeled = definition.with(label_font_family: "Cambria")
    custom = labeled.with(font_family: "Helvetica", label_font_family: "Arial")

    expect(custom.font_family).to eq("Helvetica")
    expect(custom.label_font_family).to eq("Arial")
    expect(labeled.with(label_font_family: nil).label_font_family)
      .to eq("Carlito")
  end
end
