# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe "Compartment font units" do
  let(:bounds) { Ea::Model::Bounds.new(x: 10, y: 20, width: 100, height: 80) }
  let(:operations) { %w[first second].map { |name| Ea::Model::Operation.new(name: name) } }
  let(:literals) { %w[first second].map { |name| Ea::Model::EnumerationLiteral.new(name: name) } }

  it "preserves the default pixel operation row pitch" do
    svg = Ea::Svg::EaEmitter::Element::OperationRenderer.render(
      operations, bounds: bounds, first_y: 50, family: "Cambria", size: 7
    )
    texts = Nokogiri::XML("<svg>#{svg}</svg>").css("text")

    expect(texts.map { |node| node["y"].to_i }).to eq([50, 50, 63, 63])
  end

  it "ignores source point height for explicit pixel fonts" do
    svg = Ea::Svg::EaEmitter::Element::OperationRenderer.render(
      operations, bounds: bounds, first_y: 50, family: "Carlito", size: 9,
                  size_unit: "px", logical_height: 12
    )
    texts = Nokogiri::XML("<svg>#{svg}</svg>").css("text")
    original = Ea::Svg::EaEmitter::TextRenderer.new(
      content: texts.last.text, x: 0, y: 0, family: "Carlito", size: 9
    ).to_svg

    expect(texts.map { |node| node["y"].to_i }).to eq([50, 50, 65, 65])
    expect(original).to include(%(textLength="#{texts.last["textLength"]}"))
  end

  it "keeps pixel row pitch while compacting measured Cambria point rows" do
    [
      [Ea::Svg::EaEmitter::Element::OperationRenderer, operations, [50, 50, 63, 63], [50, 50, 62, 62]],
      [Ea::Svg::EaEmitter::Element::EnumerationLiteralRenderer, literals, [50, 63], [50, 62]]
    ].each do |renderer, rows, pixel_y, point_y|
      { "px" => pixel_y, "pt" => point_y }.each do |unit, positions|
        svg = renderer.render(rows, bounds: bounds, first_y: 50, family: "Cambria", size: 7, size_unit: unit)
        texts = Nokogiri::XML("<svg>#{svg}</svg>").css("text")

        expect(texts.map { |node| node["y"].to_i }).to eq(positions)
        expect(texts.map { |node| node["style"] }).to all(include("font-size:7#{unit};"))
      end
    end
  end
end
