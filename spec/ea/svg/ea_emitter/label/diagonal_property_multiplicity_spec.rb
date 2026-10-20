# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

# QEA connectors carry no UMLDI label bounds, so the helper clears them.
RSpec.describe "Multiplicity of a Property target on a steep diagonal" do
  include DiagonalPropertyMultiplicityHelpers

  let(:fixture) { fixtures_path("issue135_multiplicity/diagonal_property_target.xmi") }

  # Published diagram: role (565,603), multiplicity (708,603), anchor (700,610).
  it "seats beside the anchor above the role baseline, like the published diagram" do
    texts = diagonal_property_texts(fixture)

    expect(texts["1"]).to eq([273.0, 193.0])
  end

  it "keeps the role seat unchanged" do
    expect(diagonal_property_texts(fixture)["+referencePoint"]).to eq([130.0, 193.0])
  end

  it "leaves the anchor seat on routes outside the plain diagonal style" do
    texts = diagonal_property_texts(fixture, mode: "2")

    expect(texts["1"]).to eq([265.0, 200.0])
  end
end
