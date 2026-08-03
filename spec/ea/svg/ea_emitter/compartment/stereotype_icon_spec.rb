# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Svg::EaEmitter::Compartment::StereotypeIcon do
  let(:bounds) { Ea::Model::Bounds.new(x: 100, y: 100, width: 80, height: 50) }

  def make_context(classifier)
    Struct.new(:classifier, :bounds, :canvas).new(classifier, bounds, nil)
  end

  it "renders a polygon for FeatureType stereotype" do
    klass = Ea::Model::Klass.new(name: "City", stereotype_refs: ["FeatureType"])
    result = described_class.render(make_context(klass))
    expect(result).to include("<polygon")
    expect(result).to include('fill="#FAF1EC"')
  end

  it "returns nil when classifier has no stereotype" do
    klass = Ea::Model::Klass.new(name: "Plain")
    expect(described_class.render(make_context(klass))).to be_nil
  end

  it "returns nil when classifier is nil" do
    expect(described_class.render(make_context(nil))).to be_nil
  end
end
