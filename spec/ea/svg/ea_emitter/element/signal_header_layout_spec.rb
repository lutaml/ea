# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Svg::EaEmitter::Element::HeaderRenderer, "Signal layout preservation" do
  let(:bounds) { Ea::Model::Bounds.new(x: 10, y: 20, width: 100, height: 70) }
  let(:lines) { [["«signal»", :normal], ["Notice", :bold]] }
  let(:options) { { bounds: bounds, first_y: 33, family: "Cambria", size: 7 } }

  [
    { family: "Carlito" }, { size: 9 }, { size_unit: "px" }, { logical_height: -10 }, { first_y: 0 }, { line_offset: 9 }
  ].each do |override|
    it "preserves #{override.inspect}" do
      explicit = options.merge(override)
      expect(described_class.line_layout(lines, **explicit, default_signal_header: true))
        .to eq(described_class.line_layout(lines, **explicit))
    end
  end

  it "preserves explicit stereotype and parent-ghost headers" do
    [[["«custom»", :normal], ["Notice", :bold]],
     [["Parent", :italic], *lines]].each do |header|
      expect(described_class.line_layout(header, **options, default_signal_header: true))
        .to eq(described_class.line_layout(header, **options))
    end
  end

  it "changes only the baselines for the observed default profile" do
    original = described_class.line_layout(lines, **options)
    adjusted = described_class.line_layout(lines, **options, default_signal_header: true)
    expect(adjusted.map(&:y)).to eq([32, 47])
    expect(adjusted.map { |line| line.to_h.except(:y) }).to eq(original.map { |line| line.to_h.except(:y) })
  end
end
