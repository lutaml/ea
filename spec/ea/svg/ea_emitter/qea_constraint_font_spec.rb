# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe "QEA constraint font units" do
  include QeaCompartmentFontHelpers

  let(:document) do
    path = File.expand_path("../../../../examples/qea/test.qea", __dir__)
    Ea::Sources::Qea::Adapter.new(cached_qea_database(path), path).to_document
  end

  it "retains source point units on both the constraint caption and rows" do
    texts = compartment_texts(document, "B58D1A53-E860-41a3-8352-11C274093E83")
    rows = texts.select { |node| ["constraints", "{pattern}"].include?(node.text) }

    expect(rows.map(&:text)).to eq(["constraints", "{pattern}"])
    expect(rows.map { |node| node["style"] }).to all(include("font-size:7pt;"))
  end
end
