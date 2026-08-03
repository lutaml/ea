# frozen_string_literal: true

require "spec_helper"
require "ea"
require "ea/svg/ea_emitter/markers"

RSpec.describe Ea::Svg::EaEmitter::Markers::Entry do
  it "compares equal when anchors match (regardless of body)" do
    a = described_class.new(style_key: :diamond_filled,
                             body: "<polygon points=\"10 10 20 20\"/>",
                             anchor: [10, 10])
    b = described_class.new(style_key: :diamond_filled,
                             body: "<polygon points=\"10 10 21 21\"/>",
                             anchor: [10, 10])
    expect(a.eql?(b)).to be(true)
    expect(a.hash == b.hash).to be(true)
  end

  it "compares unequal when anchors differ" do
    a = described_class.new(style_key: :diamond_filled, body: "x", anchor: [10, 10])
    b = described_class.new(style_key: :diamond_filled, body: "x", anchor: [20, 20])
    expect(a.eql?(b)).to be(false)
  end

  it "is deduplicated by anchor in a uniq pass" do
    entries = [
      described_class.new(style_key: :diamond_filled, body: "a", anchor: [10, 10]),
      described_class.new(style_key: :diamond_filled, body: "b", anchor: [10, 10]),
      described_class.new(style_key: :diamond_filled, body: "c", anchor: [20, 20])
    ]
    expect(entries.uniq(&:anchor).size).to eq(2)
  end

  it "returns false for eql? against non-Entry objects" do
    entry = described_class.new(style_key: :diamond_filled, body: "x", anchor: [1, 1])
    expect(entry.eql?("not an entry")).to be(false)
    expect(entry.eql?(nil)).to be(false)
  end
end
