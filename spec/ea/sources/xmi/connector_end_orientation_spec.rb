# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe "XMI connector end orientation" do
  include XmiEndOrientationHelpers

  let(:document) { oriented_document }
  let(:connectors) { oriented_connectors(document) }

  it "applies the saved bend route when SOID and EOID name the ends in reverse" do
    expect(waypoint_pairs(connectors["E5DAC21D"])).to eq([[760, 685], [760, 532], [790, 532]])
    expect(waypoint_pairs(connectors["07034165"])).to eq([[760, 685], [760, 535], [671, 535]])
  end

  it "seats both multiplicities at the saved end" do
    expect(multiplicity_seats(document)).to include(["1", 338.0, 459.0], ["0..1", 338.0, 459.0])
  end

  it "keeps a correctly oriented aggregation route" do
    expect(waypoint_pairs(connectors["A3EEB19A"])).to eq([[1210, 431], [1210, 304], [870, 304]])
  end

  it "keeps generalization routes" do
    expect(waypoint_pairs(connectors["63FFF9AA"])).to eq([[563, 439], [563, 398], [760, 398], [760, 349]])
  end

  it "leaves a self association's ends in saved order" do
    connector = oriented_connectors(oriented_document(self_association_xml))["07034165"]
    expect(connector.source_element_ref).to eq(connector.target_element_ref)
  end
end
