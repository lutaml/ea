# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Svg::EaEmitter::ConnectorRedock do
  include QeaRoutingHelpers
  include ConnectorRedockHelpers

  # Two stacked classes joined by a model relationship with no diagram link row.

  it "docks a connector without a diagram link on the 1px box outlines" do
    expect(render_phantom(connector_type: "Aggregation")).to eq("M 85 239 L 85 141")
    expect(render_phantom(connector_type: "Association")).to eq("M 85 239 L 85 141")
  end

  it "keeps other phantom types on the box edges" do
    expect(render_phantom(connector_type: "Dependency")).to eq("M 85 140 L 85 240 M 85 140")
  end

  it "docks on the outlines only for flagged Aggregation and Association, whatever the id" do
    flagged = { phantom_outline: true }

    expect(phantom_route(type: "Aggregation", id: "not-a-pc-id", style: flagged)).to eq(["M 20 99 L 20 41"])
    expect(phantom_route(type: "Association", id: "dc:1:2", style: flagged)).to eq(["M 20 99 L 20 41"])
  end

  it "keeps unflagged connectors, including ones named like phantoms, on the box edges" do
    expect(phantom_route(type: "Aggregation", id: "pc:1:2")).to eq(["M 20 100 L 20 40"])
    expect(phantom_route(type: "Association", id: "pc:1:2", style: { mode: "3" })).to eq(["M 20 100 L 20 40"])
    flagged = { phantom_outline: true }
    expect(phantom_route(type: "Dependency", id: "pc:1:2", style: flagged)).to eq(["M 20 40 L 20 100 M 20 40"])
  end
end
