# frozen_string_literal: true

require "spec_helper"
require "ea"
require "ea/svg/ea_emitter/marker/plus"

RSpec.describe Ea::Svg::EaEmitter::Marker::Plus do
  describe ".handles?" do
    it "handles the Nesting connector type" do
      expect(described_class.handles?("Nesting")).to be(true)
    end

    it "does not handle other connector types" do
      expect(described_class.handles?("Association")).to be(false)
      expect(described_class.handles?("Generalization")).to be(false)
      expect(described_class.handles?("Aggregation")).to be(false)
    end
  end

  describe ".specs_for" do
    let(:source) { [0, 0] }
    let(:target) { [50, 50] }
    let(:before_target) { [40, 40] }
    let(:after_source) { [10, 10] }

    it "returns one Spec with :nesting shape" do
      connector = Ea::Model::DiagramConnector.new(id: "c1",
                                                  connector_type: "Nesting")
      specs = described_class.specs_for(connector, source, target,
                                        before_target, after_source)
      expect(specs.size).to eq(1)
      expect(specs.first.shape).to eq(:nesting)
    end

    it "anchors the marker at the container (target) end by default" do
      connector = Ea::Model::DiagramConnector.new(id: "c1",
                                                  connector_type: "Nesting")
      specs = described_class.specs_for(connector, source, target,
                                        before_target, after_source)
      expect(specs.first.anchor).to eq(target)
    end

    it "anchors at the source end when the direction is reversed" do
      connector = Ea::Model::DiagramConnector.new(id: "c1",
                                                  connector_type: "Nesting",
                                                  direction: "Destination -> Source")
      specs = described_class.specs_for(connector, source, target,
                                        before_target, after_source)
      expect(specs.first.anchor).to eq(source)
    end
  end

  describe "ARM_LENGTH" do
    it "is 8 (16px wide plus)" do
      expect(described_class::ARM_LENGTH).to eq(8)
    end
  end
end
