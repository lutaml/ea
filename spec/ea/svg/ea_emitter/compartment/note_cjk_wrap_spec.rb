# frozen_string_literal: true

require "spec_helper"

# A note line breaks at whitespace and between a CJK character and either
# neighbour; Latin words are never split.
RSpec.describe "Note CJK line wrapping" do
  include NoteBodyWrapHelpers

  let(:note) { Ea::Svg::EaEmitter::Compartment::NoteBody }
  let(:text) { "gml:Envelopeを用いて都市計画データの空間範囲、空間参照系及び次元数を指定する。" }

  it "fills the line with CJK characters and breaks between two of them" do
    expect(wrap_note(text, 273, 9, "Carlito"))
      .to eq(%w[gml:Envelopeを用いて都市計画データの空間範囲、 空間参照系及び次元数を指定する。])
  end

  it "keeps one line when the whole text fits" do
    expect(wrap_note(text, 600, 9, "Carlito")).to eq([text])
  end

  it "never splits a Latin word between CJK characters" do
    rows = wrap_note("日本語の仕様CityGMLの定義", 40, 9, "Carlito")
    expect(rows.join).to eq("日本語の仕様CityGMLの定義")
    expect(rows.flat_map { |row| row.scan(/[A-Za-z]+/) }).to eq(["CityGML"])
  end

  it "drops the space at a space break and keeps spaces inside a line" do
    expect(wrap_note("CityGML 2.0 XML Schemaの構造", 90, 7, "Cambria"))
      .to eq(["CityGML 2.0 XML", "Schemaの構造"])
  end

  it "leaves Latin-only wrapping at whitespace" do
    expect(note.wrap_paragraph("Reference information", 119, 9, "Carlito")).to eq(["Reference information"])
    expect(note.wrap_paragraph("Reference information", 80, 9, "Carlito")).to eq(%w[Reference information])
  end
end

RSpec.describe "Note CJK rows against the native plateau notes" do
  include QeaContentHelpers
  include NoteCjkWrapHelpers

  let(:envelope_rows) do
    [["gml:Envelopeを用いて都市計画データの空間範囲、", 269],
     ["空間参照系及び次元数を指定する。", 194]]
  end

  it "reproduces the rows of the envelope note in diagram 676B9C9A" do
    expect(note_rows("676B9C9A", "gml:Envelope", 2)).to eq(envelope_rows)
  end

  it "reproduces the rows of the envelope note in diagram 926AFE38" do
    expect(note_rows("926AFE38", "gml:Envelope", 2)).to eq(envelope_rows)
  end

  it "reproduces the five rows of the CityGML note in diagram C028B286" do
    expect(note_rows("C028B286", "本UML", 5)).to eq(
      [["本UMLクラス図は、CityGML 2.0の仕様CityGML 2.0のXML", 236],
       ["Schemaの構造に合致するよう修正しているため、CityGML 2.0に示", 263],
       ["されたUMLクラス図と差異が生じている。", 157],
       ["これは、CityGML 2.0のUMLクラス図とXML Schemaの間に差異が", 257],
       ["生じていることに起因する。", 105]]
    )
  end
end

RSpec.describe "Note CJK rows keep closing punctuation attached" do
  include QeaContentHelpers
  include NoteCjkWrapHelpers

  %w[676B9C9A 926AFE38].each do |guid|
    it "emits no row holding only the closing full stop in diagram #{guid}" do
      expect(qea_texts(plateau_document, guid)).not_to include("。")
    end
  end
end
