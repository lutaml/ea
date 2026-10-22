# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Svg::EaEmitter::Connectors, "target-first bridged direct lines" do
  let(:bridges) { Ea::Svg::EaEmitter.const_get(:ConnectorBridges) }

  def connector(type, order, source, style = {})
    Ea::Model::DiagramConnector.new(connector_type: type, paint_order: order, source_element_ref: source, style: style)
  end

  let(:vertical) { [[100, 0], [100, 100]] }
  let(:horizontal) { [[0, 50], [200, 50]] }
  let(:partner) { connector("Association", [1], "B") }

  def path(carrier)
    bridges.new(nil, [[carrier, horizontal], [partner, vertical]]).path_for(carrier, horizontal)
  end

  it "writes a bridged Dependency target-first with the target repeat, like its centerline" do
    expect(path(connector("Dependency", [2], "A")))
      .to eq("M 200 50 L 106 50 A 6 6 180 0 0 94 50 L 0 50 M 200 50")
  end

  it "writes a bridged direct-style line target-first" do
    expect(path(connector("Association", [2], "A", { direct: true })))
      .to start_with("M 200 50 L 106 50 A 6 6 180 0 0 94 50")
  end

  it "keeps a bridged Association source-first" do
    expect(path(connector("Association", [2], "A")))
      .to eq("M 0 50 L 94 50 A 6 6 180 0 0 106 50 L 200 50")
  end

  it "falls back to the target-first centerline when nothing crosses" do
    carrier = connector("Dependency", [2], "A")
    expect(bridges.new(nil, [[carrier, horizontal]]).path_for(carrier, horizontal))
      .to eq("M 200 50 L 0 50 M 200 50")
  end
end
