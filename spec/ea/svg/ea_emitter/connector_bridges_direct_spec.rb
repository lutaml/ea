# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Svg::EaEmitter::Connectors, "target-first bridged direct lines" do
  include ConnectorBridgesDirectHelpers

  let(:horizontal) { [[0, 50], [200, 50]] }
  let(:partner) { bridge_connector("Association", [1], "B") }

  it "writes a bridged Dependency target-first with the target repeat, like its centerline" do
    expect(bridged_path(bridge_connector("Dependency", [2], "A"), horizontal, partner: partner))
      .to eq("M 200 50 L 106 50 A 6 6 180 0 0 94 50 L 0 50 M 200 50")
  end

  it "writes a bridged direct-style line target-first" do
    expect(bridged_path(bridge_connector("Association", [2], "A", { direct: true }), horizontal, partner: partner))
      .to start_with("M 200 50 L 106 50 A 6 6 180 0 0 94 50")
  end

  it "keeps a bridged Association source-first" do
    expect(bridged_path(bridge_connector("Association", [2], "A"), horizontal, partner: partner))
      .to eq("M 0 50 L 94 50 A 6 6 180 0 0 106 50 L 200 50")
  end

  it "falls back to the target-first centerline when nothing crosses" do
    carrier = bridge_connector("Dependency", [2], "A")
    expect(bridged_path(carrier, horizontal))
      .to eq("M 200 50 L 0 50 M 200 50")
  end
end
