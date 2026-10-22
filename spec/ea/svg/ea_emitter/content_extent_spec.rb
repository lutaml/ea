# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::ContentExtent do
  let(:fragments) do
    [
      %(<g><rect x="30" y="40" width="100" height="50" rx="0.00"/></g>),
      %(<g><path d="M 20 60 L 200 60 M 200 60 A 5 5 0 0 1 210 70"/></g>),
      %(<g><polygon points="25 35 40 45 25 55 25 35"/></g>),
      %(<g><text x="12.00" y="30.00" textLength="48" style="font-family:Cambria; font-size:7pt;">+role</text></g>)
    ]
  end

  subject(:extent) { described_class.measure(fragments) }

  it "counts only the end point of a Bezier segment, not its control points" do
    curve = described_class.measure([%(<g><path d="M 10 10 C 80 8 128 12 177 10"/></g>)])

    expect(curve.shapes).to eq([10.0, 10.0, 177.0, 10.0])
  end

  it "spans the shape points of rects, paths (arc end points) and polygons" do
    expect(extent.shapes).to eq([20.0, 35.0, 210.0, 90.0])
  end

  it "boxes a text run from its left edge, baseline minus the rounded font height, to left plus textLength" do
    expect(extent.texts).to eq([12.0, 20.0, 60.0, 30.0])
  end

  it "reports no text box for content without text" do
    expect(described_class.measure([fragments.first]).texts).to be_nil
  end
end
