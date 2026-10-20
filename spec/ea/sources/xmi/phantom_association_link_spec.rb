# frozen_string_literal: true

require "spec_helper"

RSpec.describe "XMI association drawn without a diagram link" do
  include XmiEndOrientationHelpers

  let(:document) { oriented_document(File.read(fixture)) }
  let(:fixture) { File.expand_path("../../../fixtures/phantom_association_link.xmi", __dir__) }
  let(:phantom) do
    document.diagrams.first.connectors.find { |connector| connector.relationship_ref.include?("BDC3F2BD") }
  end

  it "routes it between the element edges like the QEA phantom connector" do
    expect(waypoint_pairs(phantom)).to eq([[593, 222], [591, 320]])
    expect(phantom.style).to eq(lwidth: "1", phantom_outline: true)
  end

  it "seats the multiplicity at the QEA position" do
    expect(multiplicity_seats(document)).to eq([["0..1", 206.0, 198.0]])
  end
end
