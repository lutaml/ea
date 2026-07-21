# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::ConnectorRouter do
  let(:source_bounds) { Ea::Model::Bounds.new(x: 100, y: 100, width: 200, height: 80) }
  let(:target_bounds) { Ea::Model::Bounds.new(x: 500, y: 300, width: 200, height: 80) }

  describe "#waypoints with EDGE=2 (source right edge → target left edge)" do
    let(:router) { described_class.new(source_bounds: source_bounds, target_bounds: target_bounds, edge_code: 2) }

    it "produces a source point on the source's right edge" do
      pts = router.waypoints
      expect(pts.first[0]).to eq(300) # right edge of source
    end

    it "produces a target point on the target's left edge" do
      pts = router.waypoints
      expect(pts.last[0]).to eq(500) # left edge of target
    end

    it "produces a bend point at the intersection" do
      pts = router.waypoints
      expect(pts.size).to eq(3) # source → bend → target
      bend = pts[1]
      src = pts[0]
      tgt = pts[2]
      # Bend x = target x (horizontal routing), bend y = source y
      expect(bend[0]).to eq(tgt[0])
      expect(bend[1]).to eq(src[1])
    end
  end

  describe "#waypoints with EDGE=3 (source bottom edge → target top edge)" do
    let(:router) { described_class.new(source_bounds: source_bounds, target_bounds: target_bounds, edge_code: 3) }

    it "produces a source point on the source's bottom edge" do
      pts = router.waypoints
      expect(pts.first[1]).to eq(180) # bottom edge
    end

    it "produces a target point on the target's top edge" do
      pts = router.waypoints
      expect(pts.last[1]).to eq(300) # top edge
    end
  end

  describe "#waypoints with aligned elements (no bend)" do
    let(:aligned_target) { Ea::Model::Bounds.new(x: 500, y: 100, width: 200, height: 80) }
    let(:router) { described_class.new(source_bounds: source_bounds, target_bounds: aligned_target, edge_code: 2) }

    it "produces exactly 2 points when aligned" do
      pts = router.waypoints
      expect(pts.size).to eq(2)
    end
  end

  describe "#waypoints with nil bounds" do
    it "returns empty array when source is nil" do
      router = described_class.new(source_bounds: nil, target_bounds: target_bounds)
      expect(router.waypoints).to eq([])
    end

    it "returns empty array when target is nil" do
      router = described_class.new(source_bounds: source_bounds, target_bounds: nil)
      expect(router.waypoints).to eq([])
    end
  end
end
