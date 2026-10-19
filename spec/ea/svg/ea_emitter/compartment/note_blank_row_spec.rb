# frozen_string_literal: true

require "spec_helper"

# A single line break ends a note line; each empty source line adds one blank row.
RSpec.describe "Note blank rows from empty source lines" do
  include NoteBlankRowHelpers

  it "stacks plain lines split by a single line break with no blank row" do
    expect(paragraphs("One\r\nTwo")).to eq([["One", 0], ["Two", 0]])
    rows = baselines("One\r\nTwo", family: "Cambria", size: 7, logical_height: 10)
    expect(rows.each_cons(2).map { |a, b| b - a }).to eq([12])
  end

  it "adds one blank row per empty line, in plain and marked-up bodies" do
    expect(paragraphs("One\r\n\r\nTwo\r\n\r\n\r\nThree")).to eq([["One", 1], ["Two", 2], ["Three", 0]])
    expect(paragraphs("<b>One</b>\r\n</ul>\r\n\r\nTwo")).to eq([["One", 1], ["Two", 0]])
  end

  it "ignores trailing and leading empty lines" do
    expect(paragraphs("\r\nOne\r\n\r\n")).to eq([["One", 0]])
  end
end

RSpec.describe "Note blank rows against the native ArcGIS diagram 1" do
  include QeaContentHelpers

  it "reproduces the native baselines of the note" do
    document = Ea::Sources::Qea::Adapter.from_path("examples/qea/ArcGISWorkspace_template.qea")
    nodes = qea_text_nodes(document, "7D960BD8")
    start = nodes.index { |n| n.text.start_with?("The model is structured") }
    ys = nodes[start, 14].map { |n| n["y"].to_f }

    expect(ys.map { |y| y - ys.first }).to eq([0, 16, 32, 48, 64, 80, 112, 128, 160, 176, 192, 224, 240, 256])
  end
end
