# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Svg::EaEmitter::Element::StereotypeIconRenderer do
  let(:bounds) { Ea::Model::Bounds.new(x: 100, y: 200, width: 60, height: 40) }

  describe ".render" do
    it "returns empty string when classifier is nil" do
      result = described_class.render(classifier: nil, bounds: bounds)
      expect(result).to eq("")
    end

    it "returns empty string when bounds is nil" do
      klass = Ea::Model::Klass.new(name: "X")
      expect(described_class.render(classifier: klass, bounds: nil)).to eq("")
    end

    it "returns empty string when classifier has no stereotype" do
      klass = Ea::Model::Klass.new(name: "Plain")
      expect(described_class.render(classifier: klass, bounds: bounds)).to eq("")
    end

    it "emits a polygon for FeatureType stereotype" do
      klass = Ea::Model::Klass.new(name: "City", stereotype_refs: ["FeatureType"])
      result = described_class.render(classifier: klass, bounds: bounds)
      expect(result).to include("<polygon")
      expect(result).to include('fill="#FAF1EC"')
      expect(result).to include('stroke="#69738C"')
    end

    it "emits a polygon for Type stereotype" do
      klass = Ea::Model::Klass.new(name: "Quantity", stereotype_refs: ["Type"])
      result = described_class.render(classifier: klass, bounds: bounds)
      expect(result).to include("<polygon")
    end

    it "centers the icon at the element's center" do
      klass = Ea::Model::Klass.new(name: "City", stereotype_refs: ["FeatureType"])
      result = described_class.render(classifier: klass, bounds: bounds)
      # Center is (100+30, 200+20) = (130, 220). Diamond extends ±5.
      expect(result).to include("130,")
      expect(result).to include("220")
    end
  end
end
