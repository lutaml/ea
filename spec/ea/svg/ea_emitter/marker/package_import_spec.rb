# frozen_string: true

require "spec_helper"
require "ea"
require "ea/svg/ea_emitter/marker/registry"
require "ea/svg/ea_emitter/marker/package_import"

RSpec.describe Ea::Svg::EaEmitter::Marker::PackageImport do
  let(:connector_with_offsets) do
    Struct.new(:direction, :has_geometry_offsets).new("Source -> Destination", true)
  end
  let(:connector_without_offsets) do
    Struct.new(:direction, :has_geometry_offsets).new("Source -> Destination", false)
  end

  before do
    Ea::Svg::EaEmitter::Marker.ensure_builtins_registered!
  end

  describe ".handles?" do
    it "handles the 'Package' effective type" do
      expect(described_class.handles?("Package")).to be(true)
    end

    it "does not handle unrelated types" do
      expect(described_class.handles?("Association")).to be(false)
      expect(described_class.handles?("Generalization")).to be(false)
    end
  end

  describe ".specs_for" do
    let(:source) { [100, 50] }
    let(:target) { [200, 50] }
    let(:before_target) { [180, 50] }
    let(:after_source) { [120, 50] }

    it "returns both a :package_anchor and an :arrow spec when offsets present" do
      specs = described_class.specs_for(connector_with_offsets, source, target,
                                         before_target, after_source)
      shapes = specs.map(&:shape)
      expect(shapes).to include(:package_anchor)
      expect(shapes).to include(:arrow)
    end

    it "returns no specs when geometry offsets are absent" do
      specs = described_class.specs_for(connector_without_offsets, source, target,
                                         before_target, after_source)
      expect(specs).to eq([])
    end
  end
end
