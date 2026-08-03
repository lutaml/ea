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

    it "emits a polygon for FeatureType stereotype via fallback" do
      klass = Ea::Model::Klass.new(name: "City", stereotype_refs: ["FeatureType"])
      result = described_class.render(classifier: klass, bounds: bounds)
      expect(result).to include("<polygon")
      expect(result).to include('fill="#FAF1EC"')
      expect(result).to include('stroke="#69738C"')
    end

    it "emits a polygon for Type stereotype via fallback" do
      klass = Ea::Model::Klass.new(name: "Quantity", stereotype_refs: ["Type"])
      result = described_class.render(classifier: klass, bounds: bounds)
      expect(result).to include("<polygon")
    end

    it "centers the fallback icon at the element's center" do
      klass = Ea::Model::Klass.new(name: "City", stereotype_refs: ["FeatureType"])
      result = described_class.render(classifier: klass, bounds: bounds)
      expect(result).to include("130,")
      expect(result).to include("220")
    end
  end

  describe "ShapeScript integration" do
    let(:klass) { Ea::Model::Klass.new(name: "X", stereotype_refs: ["CustomIcon"]) }
    let(:fake_doc) do
      Struct.new(:technology_name, :stereotypes).new(
        "Test", [Struct.new(:name, :notes).new("CustomIcon",
          "shape CustomIcon { rectangle(0, 0, 8, 8); }")]
      )
    end
    let(:registry) do
      Ea::Mdg::Registry.new.tap { |r| r.register(fake_doc) }
    end

    it "uses MDG-provided ShapeScript when registry has a match" do
      result = described_class.render(classifier: klass, bounds: bounds,
                                      mdg_registry: registry)
      expect(result).to include("<rect")
      expect(result).not_to include("<polygon") # fallback bypassed
    end

    it "falls back to hardcoded when registry has no match" do
      other_klass = Ea::Model::Klass.new(name: "Y", stereotype_refs: ["FeatureType"])
      result = described_class.render(classifier: other_klass, bounds: bounds,
                                      mdg_registry: registry)
      expect(result).to include("<polygon")
    end
  end
end
