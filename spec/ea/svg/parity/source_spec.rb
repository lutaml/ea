# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Svg::Parity::Source do
  it "loads a .qea file into a model document" do
    document = described_class.new(fixtures_path("basic.qea")).load
    expect(document.diagrams.size).to be > 1
  end

  it "loads a .xmi file into a model document" do
    document = described_class.new(fixtures_path("basic.xmi")).load
    expect(document.diagrams.size).to be > 1
  end
end
