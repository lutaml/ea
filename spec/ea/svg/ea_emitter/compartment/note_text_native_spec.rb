# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Svg::EaEmitter::Compartment::NoteText do
  include NoteTextNativeHelpers

  # basic.xmi Domain Model E325B9D8: source bounds normalize by (-90, -90)
  # in the native SVG. Header baselines are 29, 29, 199; documentation is
  # at x=20/337/20, y=62/232 with a 13px row pitch.
  [[10, 10, 20, 62], [327, 10, 337, 62], [10, 180, 20, 232]].each do |x, y, note_x, note_y|
    it "matches native classifier documentation at #{x},#{y}" do
      context = native_note_text_context(left: x, top: y)
      rows = Nokogiri::XML.fragment(described_class.render(context)).css("text")

      expect(rows.map { |row| row["x"].to_f }).to eq([note_x, note_x])
      expect(rows.map { |row| row["y"].to_f }).to eq([note_y, note_y + 13])
      expect(rows.map(&:text)).to eq(["[Detailed notes that describe the ", "concept.]"])
      expect(rows.map { |row| row["style"] })
        .to all(include("font-family:Source Sans Pro;", "font-size:7pt;", "font-style:italic;"))
    end
  end

  it "preserves ordinary diagram documentation placement" do
    context = native_note_text_context(left: 10, top: 10)
    context.diagram.hand_draw = false
    rows = Nokogiri::XML.fragment(described_class.render(context)).css("text")

    expect(rows.map { |row| row["x"].to_f }).to eq([15, 15])
    expect(rows.map { |row| row["y"].to_f }).to eq([66, 79])
    expect(rows.map(&:text)).to eq(["[Detailed notes that describe the ", "concept.]"])
  end
end

RSpec.describe Ea::Svg::EaEmitter::Compartment::NoteText, "visibility" do
  include NoteTextNativeHelpers

  it "omits documentation when notes are hidden" do
    context = native_note_text_context(left: 10, top: 10)
    context.diagram.show_notes = false

    expect(described_class.render(context)).to be_nil
  end

  it "omits blank documentation" do
    context = native_note_text_context(left: 10, top: 10)
    context.classifier.annotations.first.body = " \n "

    expect(described_class.render(context)).to be_nil
  end
end
