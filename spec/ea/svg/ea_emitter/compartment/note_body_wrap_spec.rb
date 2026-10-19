# frozen_string_literal: true

require "spec_helper"

# Native lines are the EA-published note text rows (ArcGISWorkspace_template.qea
# diagram 4).
RSpec.describe Ea::Svg::EaEmitter::Compartment::NoteBody do
  include NoteBodyWrapHelpers

  describe ".wrap_paragraph" do
    it "keeps a word on the line only if its trailing space also fits" do
      text = "Use this diagram to define the spatial reference information of your schema. " \
             "You can define one or more Spatial Reference elements, which are referred to " \
             "by other elements in your schema that require Spatial Reference information, " \
             "such as a coordinate system, XYTolerance etc."

      expect(wrap_note(text, 273, 10, "Arial")).to eq(
        ["Use this diagram to define the spatial", "reference information of your schema.",
         "You can define one or more Spatial", "Reference elements, which are referred",
         "to by other elements in your schema that", "require Spatial Reference information,",
         "such as a coordinate system,", "XYTolerance etc."]
      )
    end

    it "measures at the source-selected logical height" do
      text = "Reference information"

      expect(described_class.wrap_paragraph(text, 115, 9, "Carlito", logical_height: 12)).to eq([text])
      expect(described_class.wrap_paragraph(text, 115, 9, "Carlito", logical_height: 13))
        .to eq(%w[Reference information])
      expect(described_class.wrap_paragraph(text, 115, 9, "Carlito")).to eq(%w[Reference information])
    end

    it "leaves text that fits on one line, and Latin words whole" do
      expect(wrap_note("A short note", 214, 9, "Carlito")).to eq(["A short note"])
      expect(wrap_note("Supercalifragilisticexpialidocious", 40, 9, "Carlito"))
        .to eq(["Supercalifragilisticexpialidocious"])
    end

    it "preserves adjacent mixed-script text and normalizes interword whitespace" do
      expect(wrap_note("  gml:Envelope日本語  Envelope\tを用いて  ", 500, 9, "Carlito"))
        .to eq(["gml:Envelope日本語 Envelope を用いて"])
      expect(wrap_note("  \t ", 40, 9, "Carlito")).to eq([])
    end

    it "allows the last word to fit without an extra trailing space" do
      expect(described_class.wrap_paragraph("Reference information", 119, 9, "Carlito"))
        .to eq(["Reference information"])
    end

    it "measures mixed-script lines using the same whole-line fallback as emission" do
      expect(wrap_note("日本+roleTwo", 51, 7, "Cambria")).to eq(["日本+roleTwo"])
    end
  end
end

RSpec.describe "Note source logical height" do
  [
    [12, ["Reference information"], [111], [45]],
    [13, %w[Reference information], [53, 63], [46, 61]],
    [nil, %w[Reference information], [53, 63], [46, 61]]
  ].each do |height, texts, lengths, baselines|
    it "uses source height #{height.inspect} for wrapping and emitted textLength" do
      context = Ea::Svg::EaEmitter::RenderContext.new(
        bounds: Ea::Model::Bounds.new(x: 10, y: 20, width: 119, height: 80),
        model_element: Ea::Model::Note.new(id: "N1", body: "Reference information"),
        family: "Carlito", size: 9, size_unit: "pt", logical_height: height,
        theme: Ea::Theme::Registry.default
      )
      svg = Ea::Svg::EaEmitter::Compartment::NoteBody.render(context)
      rows = Nokogiri::XML.fragment(svg).css("text")

      expect(rows.map(&:text)).to eq(texts)
      expect(rows.map { |row| row["textLength"].to_i }).to eq(lengths)
      expect(rows.map { |row| row["y"].to_f }).to eq(baselines)
      expect(rows.map { |row| row["style"] }).to all(include("font-size:9pt"))
    end
  end
end
