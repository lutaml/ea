# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

RSpec.describe "Ea::Fonts::Metrics.gdi_cell_metrics" do
  [
    ["Arial", 13, [13, 3]], # VDMX; rounded win metrics would give [12, 3]
    ["Arial", 14, [13, 3]],
    ["Cambria", 10, [10, 2]],
    ["Carlito", 13, [12, 3]],
    ["Calibri", 13, [12, 3]]
  ].each do |family, height, cell|
    it "returns #{cell.inspect} for #{family} at logical height #{height}" do
      expect(Ea::Fonts::Metrics.gdi_cell_metrics(family, height)).to eq(cell)
    end
  end

  it "returns nil for a family without vertical data" do
    expect(Ea::Fonts::Metrics.gdi_cell_metrics("Source Sans Pro", 13)).to be_nil
  end
end

module NoteVerticalHelpers
  # Baselines of a two-paragraph note, relative to the note top.
  def note_rows(family:, size:, logical_height: nil)
    context = Ea::Svg::EaEmitter::RenderContext.new(
      bounds: Ea::Model::Bounds.new(x: 10, y: 100, width: 400, height: 200),
      model_element: Ea::Model::Note.new(id: "N1", body: "First\nSecond"),
      family: family, size: size, size_unit: "pt", logical_height: logical_height,
      theme: Ea::Theme::Registry.default
    )
    svg = Ea::Svg::EaEmitter::Compartment::NoteBody.render(context)
    Nokogiri::XML.fragment(svg).css("text").map { |row| row["y"].to_f - 100 }
  end

  def diagram_svg(path, guid)
    document = Ea::Sources::Qea::Adapter.from_path(path)
    diagram = document.diagrams.find { |entry| entry.id.include?(guid) }
    svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id,
                                                    document: document).render
    Nokogiri::XML(svg).remove_namespaces!
  end

  # Tops of path shapes whose first edge is horizontal (note outlines among them).
  def shape_tops(xml)
    xml.xpath("//path").filter_map { |node| node["d"][/\AM \d+ (\d+) L \d+ \1 L/, 1]&.to_i }
  end

  # [shape tops, first two baselines starting at first_line].
  def note_layout(path, guid, first_line)
    xml = diagram_svg(path, guid)
    tops = shape_tops(xml)
    rows = xml.xpath("//text").map { |node| [node.text, node["y"].to_f] }
    start = rows.index { |text, _| text.start_with?(first_line) }
    [tops, rows[start, 2].map(&:last)]
  end
end

RSpec.describe "Note first baseline and line pitch" do
  include NoteVerticalHelpers

  # Native first-baseline offsets from the note top and line pitches:
  # Arial 9pt/10pt ArcGIS d1/d4, Cambria 7pt plateau d27, Carlito 9pt d28/d70.
  [
    ["Arial", 9, 13, 27, 16],
    ["Arial", 10, 14, 27, 16],
    ["Cambria", 7, 10, 24, 12],
    ["Carlito", 9, 13, 26, 15]
  ].each do |family, size, height, offset, pitch|
    it "places #{family} #{size}pt at offset #{offset} with pitch #{pitch}" do
      first, second = note_rows(family: family, size: size, logical_height: height)

      expect(first).to eq(offset)
      expect(second - first).to eq(pitch * 2) # "\n" adds one blank pitch row
    end
  end
end

RSpec.describe "Note vertical layout without font data" do
  include NoteVerticalHelpers

  it "keeps size+9 and size+7 for a family without vertical data" do
    first, second = note_rows(family: "Source Sans Pro", size: 9)

    expect(first).to eq(18)
    expect(second - first).to eq(32)
  end
end

RSpec.describe "QEA note vertical placement against native" do
  include NoteVerticalHelpers

  [
    ["examples/qea/ArcGISWorkspace_template.qea", "7C44AC09", "Use this diagram", 27, 16],
    ["examples/qea/ArcGISWorkspace_template.qea", "7D960BD8", "The model is structured", 27, 16],
    ["examples/qea/20251010_current_plateau_v5.1.qea", "C028B286", "本UMLクラス図", 24, 12]
  ].each do |path, guid, first_line, offset, pitch|
    it "matches the native offset #{offset} and pitch #{pitch} in diagram #{guid}" do
      tops, (first, second) = note_layout(path, guid, first_line)

      expect(tops).to include(first - offset)
      expect(second - first).to eq(pitch)
    end
  end
end
