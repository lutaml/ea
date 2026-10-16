# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::EaEmitter::Marker::Registry do
  let(:connector) do
    Ea::Model::DiagramConnector.new(
      id: "dc1",
      connector_type: connector_type,
      direction: direction,
      waypoints: [
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 0, y: 0)),
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 100, y: 0))
      ]
    )
  end
  let(:source) { [0, 0] }
  let(:target) { [100, 0] }
  let(:before_target) { [0, 0] }
  let(:after_source) { [100, 0] }

  def specs(connector_type, direction = "Source -> Destination", relationship: nil)
    connector = Ea::Model::DiagramConnector.new(
      id: "dc",
      connector_type: connector_type,
      direction: direction,
      waypoints: [
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 0, y: 0)),
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 100, y: 0))
      ]
    )
    described_class.specs_for(connector, connector_type,
                              [0, 0], [100, 0], [0, 0], [100, 0],
                              relationship: relationship)
  end

  it "keeps source-owned aggregations arrowless" do
    out = specs("Aggregation")
    expect(out.map(&:shape)).to eq(%i[diamond])
    expect(out.map(&:anchor)).to eq([[0, 0]])
  end

  it "places reverse aggregation arrows at source while retaining target diamond" do
    out = specs("Aggregation", "Destination -> Source")
    expect(out.map(&:shape)).to eq(%i[diamond arrow])
    expect(out.map(&:anchor)).to eq([[100, 0], [0, 0]])
  end

  it "preserves target-owned diamonds when direction points to source" do
    relationship = Ea::Model::Association.new(
      id: "rel", source_id: "source", target_id: "target",
      source_aggregation: "none", target_aggregation: "composite"
    )
    out = specs("Aggregation", "Destination -> Source",
                relationship: relationship)
    expect(out.map(&:shape)).to eq(%i[diamond arrow])
    expect(out.map(&:anchor)).to eq([[100, 0], [0, 0]])
  end

  it "keeps source-owned reverse aggregations arrowless" do
    relationship = Ea::Model::Association.new(
      id: "rel", source_id: "source", target_id: "target",
      source_aggregation: "composite", target_aggregation: "none"
    )
    out = specs("Aggregation", "Destination -> Source",
                relationship: relationship)
    expect(out.map(&:shape)).to eq(%i[diamond])
    expect(out.map(&:anchor)).to eq([[0, 0]])
  end

  it "keeps source-owned compositions arrowless" do
    out = specs("Composition", "Source -> Destination")
    expect(out.map(&:shape)).to eq(%i[diamond])
    expect(out.map(&:anchor)).to eq([[0, 0]])
  end

  it "preserves the target arrow for bidirectional aggregation" do
    relationship = Ea::Model::Association.new(
      id: "rel", source_id: "source", target_id: "target",
      source_aggregation: "none", target_aggregation: "composite"
    )
    out = specs("Aggregation", "Bi-Directional",
                relationship: relationship)
    expect(out.map(&:shape)).to eq(%i[diamond arrow])
    expect(out.map(&:anchor)).to eq([[100, 0], [100, 0]])
  end

  it "preserves the target arrow for unspecified aggregation direction" do
    relationship = Ea::Model::Association.new(
      id: "rel", source_id: "source", target_id: "target",
      source_aggregation: "none", target_aggregation: "composite"
    )
    out = specs("Aggregation", "Unspecified", relationship: relationship)
    expect(out.map(&:shape)).to eq(%i[diamond arrow])
    expect(out.map(&:anchor)).to eq([[100, 0], [100, 0]])
  end

  it "dispatches Generalization to OpenTriangle" do
    out = specs("Generalization")
    expect(out.map(&:shape)).to eq([:triangle])
  end

  it "dispatches Association to ArrowPath" do
    out = specs("Association")
    expect(out.map(&:shape)).to eq([:arrow])
  end

  it "returns no specs for unknown connector type" do
    expect(specs("UnknownType")).to eq([])
  end

  it "flips anchor end when direction is Destination -> Source" do
    connector = Ea::Model::DiagramConnector.new(
      id: "dc",
      connector_type: "Aggregation",
      direction: "Destination -> Source",
      waypoints: [
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 0, y: 0)),
        Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: 100, y: 0))
      ]
    )
    out = described_class.specs_for(connector, "Aggregation",
                                    [0, 0], [100, 0], [0, 0], [100, 0])
    diamond = out.find { |s| s.shape == :diamond }
    # whole_end_at_source is false → diamond anchor = target
    expect(diamond.anchor).to eq([100, 0])
  end

  context "when registering a custom kind" do
    after do
      # Clean up: remove the test kind from the registry via the
      # public kinds reader (Array#pop mutates the underlying list).
      described_class.kinds.pop
    end

    it "supports adding new kinds without modifying existing code (OCP)" do
      custom_kind = Class.new(Ea::Svg::EaEmitter::Marker::Kind) do
        def self.handles?(type)
          type == "CustomType"
        end

        def self.specs_for(_connector, *_args)
          [Ea::Svg::EaEmitter::Marker::Registry::Spec.new(shape: :diamond,
                                                           anchor: [0, 0],
                                                           base: [10, 0])]
        end
      end
      described_class.register(custom_kind)

      out = specs("CustomType")
      expect(out.map(&:shape)).to eq([:diamond])
    end
  end
end
