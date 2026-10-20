# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Sources::Xmi::ClassifierBuilder do
  let(:classifiers) { Ea::Sources::Xmi::Adapter.from_path(fixtures_path("basic.xmi")).classifiers }

  let(:bodies) do
    ->(name) { classifiers.find { |c| c.name == name }.annotations.map { |a| [a.kind, a.body] } }
  end

  it "maps the Extension documentation property to a documentation annotation" do
    expect(bodies.call("Concept A")).to eq([["documentation", "[Detailed notes that describe the concept.]"]])
  end

  it "keeps the documentation text verbatim" do
    expect(bodies.call("Concept B")).to eq([["documentation", "[Detailed notes that describe the concept.]\n"]])
  end

  it "leaves classifiers without documentation unannotated" do
    expect(classifiers.map { |c| c.annotations.size }.tally).to eq(0 => 30, 1 => 3)
  end
end
