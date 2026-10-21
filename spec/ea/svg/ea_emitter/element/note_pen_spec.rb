# frozen_string_literal: true

require "spec_helper"
require "ea"

# EA never sets the note pen: the outline keeps the cap and join left by the
# previous drawing, or the initial square/miter pen when the note is first.
RSpec.describe Ea::Svg::EaEmitter::Element::NoteShapeRenderer do # rubocop:disable Metrics/BlockLength
  let(:legend) do
    Ea::Model::Legend.new(
      title: "Legend", background_color: 0xF0F0F0, border_color: 0xD7D7D7,
      items: [Ea::Model::LegendItem.new(name: "Item", background_color: 0xCCFFCC, sort_index: 0)]
    )
  end
  let(:index) do
    { "note" => Ea::Model::Note.new(id: "note", name: "N", body: "text"),
      "legend" => Ea::Model::Note.new(id: "legend", name: "L", legend: legend),
      "a" => Ea::Model::Klass.new(id: "a", name: "Alpha") }
  end

  # refs are listed in paint order (EA paints the highest z_order first).
  def render(*refs)
    elements = refs.each_with_index.map do |ref, i|
      Ea::Model::DiagramElement.new(
        model_element_ref: ref, z_order: refs.size - i,
        bounds: Ea::Model::Bounds.new(x: 10 + (i * 150), y: 10, width: 120, height: 80)
      )
    end
    Ea::Svg::EaEmitter::Document.new(Ea::Model::Diagram.new(elements: elements), model_index: index,
                                                                                 content_anchor: false).render
  end

  def note_pens(svg)
    svg.scan(/<g style="[^"]*?linecap:(\w+);stroke-linejoin:(\w+);[^"]*fill:#DCDCDC/).uniq
  end

  it "uses the initial square/miter pen when the note is painted first" do
    expect(note_pens(render("note"))).to eq([%w[square miter]])
  end

  it "keeps round/bevel after a class" do
    expect(note_pens(render("a", "note"))).to eq([%w[round bevel]])
  end

  it "inherits the square/miter pen left by a first-painted legend" do
    expect(note_pens(render("legend", "note"))).to eq([%w[square miter]])
  end

  it "draws the note text group with the note pen" do
    svg = render("note")
    text_pen = /<g style="[^"]*?linecap:(\w+);stroke-linejoin:(\w+);[^"]*fill:#000000;[^"]*stroke-opacity:0.00/
    expect(svg.scan(text_pen).uniq).to eq([%w[square miter]])
  end

  it "keeps a second note square/miter after a first-painted note" do
    expect(note_pens(render("note", "note"))).to eq([%w[square miter]])
  end
end
