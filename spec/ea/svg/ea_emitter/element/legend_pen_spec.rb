# frozen_string_literal: true

require "spec_helper"
require "ea"

# EA leaves the legend pen to whatever was drawn before it, exactly as it
# does for notes: square/miter when the legend is the first thing painted,
# otherwise the pen the previous drawing left behind.
RSpec.describe Ea::Svg::EaEmitter::Element::LegendRenderer do # rubocop:disable Metrics/BlockLength
  let(:bounds) { Ea::Model::Bounds.new(x: 100, y: 50, width: 194, height: 120) }
  let(:legend) do
    Ea::Model::Legend.new(
      title: "Legend", background_color: 0xF0F0F0, border_color: 0xD7D7D7,
      items: [Ea::Model::LegendItem.new(name: "Item", background_color: 0xCCFFCC, sort_index: 0)]
    )
  end

  def caps(svg)
    svg.scan(/stroke-linecap:(\w+);stroke-linejoin:(\w+)/).uniq
  end

  it "uses the square/miter pen when painted first" do
    svg = described_class.render(bounds, legend: legend, family: "Carlito")

    expect(caps(svg)).to eq([%w[square miter]])
  end

  it "uses the pen left by the previous drawing" do
    svg = described_class.render(bounds, legend: legend, family: "Carlito", pen: %w[round bevel])

    expect(caps(svg)).to eq([%w[round bevel]])
  end

  it "derives the pen from paint position through the document render path" do
    placement = lambda do |ref, z, element|
      Ea::Model::DiagramElement.new(model_element_ref: ref, z_order: z,
                                    bounds: Ea::Model::Bounds.new(x: 10, y: 10, width: 120, height: 80),
                                    **element)
    end
    index = { "legend" => Ea::Model::Note.new(id: "legend", name: "L", legend: legend),
              "a" => Ea::Model::Klass.new(id: "a", name: "Alpha") }
    render = lambda do |elements|
      Ea::Svg::EaEmitter::Document.new(Ea::Model::Diagram.new(elements: elements), model_index: index,
                                                                                   content_anchor: false).render
    end
    first = render.call([placement.call("legend", 1, {})])
    later = render.call([placement.call("legend", 1, {}), placement.call("a", 2, {})])

    expect(caps(first)).to include(%w[square miter])
    expect(caps(later)).not_to include(%w[square miter])
  end

  describe "pen left by a preceding note or legend" do
    let(:note_model) { Ea::Model::Note.new(id: "note", name: "N", body: "text") }
    let(:index) do
      { "legend" => Ea::Model::Note.new(id: "legend", name: "L", legend: legend), "note" => note_model,
        "a" => Ea::Model::Klass.new(id: "a", name: "Alpha") }
    end

    def pens_in_paint_order(refs)
      elements = refs.each_with_index.map do |ref, i|
        Ea::Model::DiagramElement.new(model_element_ref: ref, z_order: refs.size - i,
                                      bounds: Ea::Model::Bounds.new(x: 10 + (i * 150), y: 10, width: 120, height: 80))
      end
      svg = Ea::Svg::EaEmitter::Document.new(Ea::Model::Diagram.new(elements: elements), model_index: index,
                                                                                         content_anchor: false).render
      caps(svg)
    end

    it "gives a legend after a first-painted note the note's square/miter pen" do
      expect(pens_in_paint_order(%w[note legend])).to eq([%w[square miter]])
    end

    it "gives a legend after a first-painted legend the square/miter pen" do
      expect(pens_in_paint_order(%w[legend legend])).to eq([%w[square miter]])
    end

    it "keeps the round/bevel pen for a legend after a class" do
      expect(pens_in_paint_order(%w[a legend])).to eq([%w[round bevel]])
    end

    it "keeps the pen a legend leaves for the note after it" do
      expect(pens_in_paint_order(%w[legend note])).to eq([%w[square miter]])
    end
  end
end
