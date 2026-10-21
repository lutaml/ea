# frozen_string_literal: true

require "spec_helper"
require "ea"
require "ea/svg/ea_emitter/element/legend_renderer"

# EA leaves the legend pen to whatever was drawn before it: square/miter
# when the legend is the first thing painted, round/bevel otherwise.
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
    svg = described_class.render(bounds, legend: legend, family: "Carlito", first_painted: true)

    expect(caps(svg)).to eq([%w[square miter]])
  end

  it "uses the round/bevel pen when painted after another shape" do
    svg = described_class.render(bounds, legend: legend, family: "Carlito")

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
end
