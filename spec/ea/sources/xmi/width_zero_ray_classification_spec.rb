# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.shared_context "saved thin XMI ray inputs" do
  let(:style) { { umldi_route: true, mode: "3", lwidth: "0" } }
  let(:model) { Ea::Model::DiagramConnector.new(connector_type: "Association", style: style, waypoints: []) }
  let(:link) { described_class::Link.new("Mode=3;LWidth=0;", path, "") }
  let(:path) { "" }
  let(:bounds) do
    { source: Ea::Model::Bounds.new(x: 570, y: 480, width: 404, height: 111),
      target: Ea::Model::Bounds.new(x: 660, y: 250, width: 100, height: 120) }
  end
  let(:offsets) { { source: [68, 54], target: [0, 0] } }
end

RSpec.describe Ea::Sources::Xmi::StoredRoute do
  include_context "saved thin XMI ray inputs"

  subject(:metadata) do
    described_class.new.association_route(model, link: link, bounds: bounds, offsets: offsets, edge: 1)
  end

  it "returns classification alone, leaving authored geometry owned by UMLDI" do
    expect(metadata).to eq(style: style.merge(stored_association_ray: true, association_ray_outline: true))
  end

  context "with an authored bend" do
    let(:path) { "700:400;" }

    it("does not classify a straight saved ray") { expect(metadata).to eq({}) }
  end

  context "with a tree route" do
    let(:style) { super().merge(tree: "V") }

    it("keeps the tree classification") { expect(metadata).to eq({}) }
  end

  context "with absent source offsets" do
    let(:offsets) { { source: [nil, nil], target: [0, 0] } }

    it("does not invent a saved ray") { expect(metadata).to eq({}) }
  end

  context "with an origin outside its target" do
    let(:offsets) { { source: [68, 54], target: [200, 0] } }

    it("rejects the invalid origin") { expect(metadata).to eq({}) }
  end
end
