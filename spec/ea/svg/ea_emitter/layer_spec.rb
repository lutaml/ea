# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::Layer do
  let(:layer) do
    described_class.new(
      style_key: :connector_line,
      style: "stroke-width:2; stroke:#000000",
      body: "<path d=\"M 0 0 L 100 0\"/>"
    )
  end

  describe "#to_svg" do
    it "wraps body in a <g> with the given style" do
      expect(layer.to_svg).to eq(
        %(<g style="stroke-width:2; stroke:#000000">\n<path d="M 0 0 L 100 0"/>\n</g>)
      )
    end

    it "preserves multi-line bodies verbatim" do
      multi = described_class.new(
        style_key: :x,
        style: "fill:none",
        body: "<path d=\"M 0 0 L 1 0\"/>\n<path d=\"M 0 0 L 0 1\"/>"
      )
      expect(multi.to_svg).to include("<path d=\"M 0 0 L 1 0\"/>\n<path d=\"M 0 0 L 0 1\"/>")
    end
  end

  describe "struct fields" do
    it "exposes style_key for grouping/bucketing" do
      expect(layer.style_key).to eq(:connector_line)
    end

    it "exposes style for SVG emission" do
      expect(layer.style).to eq("stroke-width:2; stroke:#000000")
    end

    it "exposes body containing child elements" do
      expect(layer.body).to include("<path")
    end
  end
end
