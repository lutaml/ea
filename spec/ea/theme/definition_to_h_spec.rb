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
  describe "label typography overrides" do
    let(:labels) do
      definition.with(label_font_family: "Cambria", label_font_size: 7,
                      label_font_size_unit: "pt")
    end

    it "loads theme39 labels without changing any global appearance field" do
      theme = Ea::Theme::Registry.lookup(":39")
      omitted = %i[id name label_font_family label_font_size label_font_size_unit]

      expect(theme.id).to eq("39")
      expect([theme.label_font_family, theme.label_font_size, theme.label_font_size_unit])
        .to eq(["Cambria", 7, "pt"])
      expect(theme.to_h.reject { |key, _| omitted.include?(key) })
        .to eq(Ea::Theme::Registry.default.to_h.reject { |key, _| omitted.include?(key) })
    end

    it "falls back to the global size and unit without storing resolved values" do
      theme = definition.with(font_size: 11, font_size_unit: "px")

      expect([theme.label_font_size, theme.label_font_size_unit]).to eq([11, "px"])
      expect(theme.to_h.values_at(:label_font_size, :label_font_size_unit)).to eq([nil, nil])
      # The default theme stores Cambria 7pt connector labels: no published
      # EA SVG uses the former Yu Gothic UI fallback (test B58D1A53 native).
      expect(Ea::Theme::Registry.default.label_font_size).to eq(7)
      expect(Ea::Theme::Registry.default.label_font_size_unit).to eq("pt")
    end

    it "clears only the corresponding inherited override on a global change" do
      resized = labels.with(font_size: 12)
      reunitized = labels.with(font_size_unit: "px")

      expect([resized.label_font_size, resized.label_font_size_unit]).to eq([12, "pt"])
      expect([reunitized.label_font_size, reunitized.label_font_size_unit]).to eq([7, "px"])
      expect(labels.with(font_size: nil).label_font_size).to be_nil
      expect(labels.with(font_size_unit: nil).label_font_size_unit).to be_nil
    end

    it "honors explicit label values alongside global changes and through round trips" do
      changed = labels.with(font_size: 13, font_size_unit: "px",
                            label_font_size: 9, label_font_size_unit: "pt")
      restored = described_class.new(**changed.to_h)

      expect(restored.to_h).to eq(changed.to_h)
      expect([restored.label_font_size, restored.label_font_size_unit]).to eq([9, "pt"])
      expect(labels.with(text_color: "#123456").label_font_size).to eq(7)
      expect(labels.with(label_font_size: nil).label_font_size).to eq(7)
    end

    it "loads explicit label size and unit independently from custom global values" do
      Tempfile.create(["label-theme", ".yml"]) do |file|
        file.write("id: label-custom\nfont:\n  size: 11\n  unit: px\nlabel_font:\n  size: 9\n  unit: pt\n")
        file.flush
        theme = Ea::Theme::Loader.load_file(file.path)

        expect([theme.font_size, theme.font_size_unit]).to eq([11, "px"])
        expect([theme.label_font_size, theme.label_font_size_unit]).to eq([9, "pt"])
      end
    end
  end
end
