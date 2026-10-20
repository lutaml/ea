# frozen_string_literal: true

require "spec_helper"

RSpec.describe "XMI uml:Text legend elements" do
  include XmiLegendNotesHelpers

  let(:notes) { adapter_with_text_notes.notes.to_h { |note| [note.id, note] } }
  let(:legend) { notes.fetch("EAID_LEG1").legend }

  it "builds a Text note carrying a legend" do
    expect(notes.fetch("EAID_LEG1").note_type).to eq("Text")
  end

  it "reads the legend title and style settings" do
    expect([legend.title, legend.heading_size, legend.font_color,
            legend.background_color, legend.border_color,
            legend.background_is_default])
      .to eq(["Key", 16, 6_303_744, 11_646_651, 10_659_756, false])
  end

  it "reads the legend items in order" do
    expect(legend.items.map { |i| [i.name, i.background_color, i.pen_color, i.pen_size, i.sort_index] })
      .to eq([["Alpha", 12_648_352, 0, 1, 0], ["Beta", 13_434_879, 5, 2, 1]])
  end

  it "keeps a Text element without legend xrefs as a plain Text note" do
    plain = notes.fetch("EAID_TXT1")
    expect([plain.note_type, plain.body, plain.legend]).to eq(["Text", "free text", nil])
  end

  it "keeps uml:Note notes unchanged" do
    note = notes.fetch("EAID_NOTE1")
    expect([note.note_type, note.body, note.legend]).to eq(["Note", "a note", nil])
  end
end
