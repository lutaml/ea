# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA notes with HTML markup" do
  include QeaContentHelpers

  let(:document) { Ea::Sources::Qea::Adapter.from_path("examples/qea/ArcGISWorkspace_template.qea") }
  let(:nodes) { qea_text_nodes(document, "7D960BD8") }
  let(:texts) { nodes.map(&:text) }

  it "renders list items as dash lines and drops the tags" do
    expect(texts).to include('- Feature classes are contained in the "Features" package.',
                             "Extensions > ArcGIS > Export to ArcGIS Workspace XML")
    expect(texts.grep(%r{</?(?:ul|li|b)>})).to be_empty
  end

  it "stacks list items on consecutive rows with no blank row between them" do
    ys = ['- Feature classes are contained in the "Features" package.',
          '- Object classes are contained in the "Tables" package.'].map do |line|
      nodes.find { |node| node.text == line }["y"].to_f
    end

    expect(ys.last - ys.first).to eq(2 * 16)
  end

  it "leaves a plain note body as one paragraph per line" do
    paragraphs = Ea::Svg::EaEmitter::Compartment::NoteHtml.paragraphs("First line\r\nSecond <not tags")

    expect(paragraphs.map { |paragraph| paragraph.text.strip }).to eq(["First line", "Second <not tags"])
    expect(paragraphs.map(&:tight)).to eq([false, false])
  end
end

RSpec.describe Ea::Svg::EaEmitter::Compartment::NoteHtml do
  it "turns <br> into a line break instead of joining the words" do
    paragraphs = described_class.paragraphs("First<br>Second<br/>Third\nNext")

    expect(paragraphs.map(&:text)).to eq(%w[First Second Third Next])
    expect(paragraphs.map(&:tight)).to eq([true, true, false, false])
  end

  it "bullets only the first segment of a list item broken by <br>" do
    paragraphs = described_class.paragraphs("<ul>\n<li>First<br>Second</li>\n<li>Next</li>\n</ul>")

    expect(paragraphs.map(&:text)).to eq(["- First", "Second", "- Next"])
    expect(paragraphs.map(&:tight)).to eq([true, true, false])
  end

  it "emits the segments of a <br> note on consecutive rows" do
    note = Ea::Model::Note.new(id: "N1", name: "Note", body: "<li>First<br>Second</li>")
    context = Ea::Svg::EaEmitter::RenderContext.new(
      element: nil, bounds: Ea::Model::Bounds.new(x: 0, y: 0, width: 200, height: 80),
      model_element: note, classifier: nil, fill: "#FFF", stroke: "#000", stroke_width: 2,
      text_fill: "#000", family: "Carlito", size: 9, size_unit: "pt",
      header_lines: [], attr_lines: [], op_lines: [], enum_literals: [], tagged_values: [],
      geometry: nil, theme: Ea::Theme::Registry.default, canvas: nil
    )
    svg = Ea::Svg::EaEmitter::Compartment::NoteBody.render(context)
    rows = svg.scan(%r{y="([\d.]+)"[^>]*>([^<]*)</text>}).to_h { |y, text| [text, y.to_f] }

    expect(rows.keys).to eq(["- First", "Second"])
    expect(rows["Second"] - rows["- First"]).to eq(15)
  end
end
