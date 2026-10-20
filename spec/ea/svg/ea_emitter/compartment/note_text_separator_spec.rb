# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Classifier documentation word separators" do
  include QeaContentHelpers
  # EA's E325B9D8 native SVG retains this separator and measures it as 130.
  [
    [Ea::Sources::Qea::Adapter, "examples/qea/basic.qea", "Source Sans Pro", 130],
    [Ea::Sources::Xmi::Adapter, "spec/fixtures/basic.xmi", "Source Sans Pro", 130]
  ].each do |adapter, path, family, wrapped_length|
    it "retains the native wrapped separator from #{File.extname(path)} documentation" do
      document = QeaBridgeCorpusHelpers.document_for(adapter, path)
      rows = qea_text_nodes(document, "E325B9D8").select { |node| node.text.start_with?("[Detailed", "concept.]") }

      expect(rows.map(&:text)).to eq(["[Detailed notes that describe the ", "concept.]"] * 3)
      expect(rows.map { |node| node["textLength"].to_i }).to eq([wrapped_length, 36] * 3)
      expect(rows.map { |node| [node["x"].to_f, node["y"].to_f] })
        .to eq([[45, 262], [45, 275], [362, 92], [362, 105], [45, 92], [45, 105]])
      expect(rows.each_slice(2).map { |first, last| last["y"].to_f - first["y"].to_f }).to eq([13] * 3)
      expect(rows.map { |node| node["space"] }).to all(eq("preserve"))
      expect(rows.map { |node| node["style"] }).to all(include("font-family:#{family};", "font-size:7pt;"))
    end
  end
end

RSpec.describe "Classifier documentation whitespace preservation" do
  include NoteTextSeparatorHelpers

  it "keeps unwrapped content and XML escaping without adding a separator" do
    rows = documentation_rows("  A & <B>\nC  ", width: 500)

    expect(rows.map(&:text)).to eq(["A & <B>\nC"])
  end

  it "normalizes wrapped whitespace and retains only the consumed word separator" do
    rows = documentation_rows("  alpha\t beta\r\ngamma   delta  ", width: 70)

    expect(rows.map(&:text)).to eq(["alpha beta ", "gamma delta"])
  end

  it "omits empty annotations and documentation hidden by the diagram" do
    expect(documentation_rows(" \r\n\t ", width: 70)).to be_empty
    expect(documentation_rows("alpha beta gamma", width: 70, shown: false)).to be_empty
  end
end
