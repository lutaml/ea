# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Svg::EaEmitter::Element::HeaderLinePipeline do
  describe ".for" do
    it "emits bold name only for a plain Klass" do
      klass = Ea::Model::Klass.new(name: "Plain")
      lines = described_class.for(klass, diagram_package_id: nil)
      expect(lines).to eq([["Plain", :bold]])
    end

    it "emits bold_italic name for an abstract Klass" do
      klass = Ea::Model::Klass.new(name: "Abs", is_abstract: true)
      lines = described_class.for(klass, diagram_package_id: nil)
      expect(lines).to eq([["Abs", :bold_italic]])
    end

    it "emits «enumeration» stereotype + bold name for Enumeration" do
      enum = Ea::Model::Enumeration.new(name: "Color")
      lines = described_class.for(enum, diagram_package_id: nil)
      expect(lines).to eq([["«enumeration»", :normal], ["Color", :bold]])
    end

    it "emits «dataType» stereotype for DataType" do
      dt = Ea::Model::DataType.new(name: "Quantity")
      lines = described_class.for(dt, diagram_package_id: nil)
      expect(lines).to eq([["«dataType»", :normal], ["Quantity", :bold]])
    end

    it "emits single bold line for InstanceSpecification (provider short-circuits)" do
      inst = Ea::Model::InstanceSpecification.new(name: "red",
                                                  classifier_name: "Color")
      lines = described_class.for(inst)
      expect(lines).to eq([["red: Color", :bold]])
    end

    it "prepends off-canvas parent ghost as italic" do
      klass = Ea::Model::Klass.new(name: "Child")
      lines = described_class.for(klass,
                                  diagram_package_id: nil,
                                  off_canvas_parent_name: "Parent")
      expect(lines.first).to eq(["Parent", :italic])
      expect(lines.last).to eq(["Child", :bold])
    end

    it "prefers umldi_keyword over stereotype_refs" do
      klass = Ea::Model::Klass.new(name: "X", stereotype_refs: ["Foo"])
      lines = described_class.for(klass, diagram_package_id: nil,
                                  umldi_keyword: "Type")
      expect(lines).to eq([["«Type»", :normal], ["X", :bold]])
    end

    it "emits the instance's own stereotype line verbatim" do
      inst = Ea::Model::InstanceSpecification.new(name: "SU_PB2",
                                                  classifier_name: "LA_SpatialUnit",
                                                  stereotype: "featureType")
      lines = described_class.for(inst)
      expect(lines.first).to eq(["«featureType»", :normal])
      expect(lines.last).to eq(["SU_PB2: LA_SpatialUnit", :bold])
    end

    it "suppresses the instance stereotype under HideEStereo" do
      inst = Ea::Model::InstanceSpecification.new(name: "Aurora",
                                                  classifier_name: "LA_Party",
                                                  stereotype: "featureType")
      lines = described_class.for(inst, suppress_stereotypes: true)
      expect(lines).to eq([["Aurora: LA_Party", :bold]])
    end

    it "suppresses classifier stereotypes under HideEStereo" do
      dt = Ea::Model::DataType.new(name: "Quantity", stereotype_refs: ["Foo"])
      lines = described_class.for(dt, diagram_package_id: nil,
                                  suppress_stereotypes: true)
      expect(lines).to eq([["Quantity", :bold]])
    end
  end

  describe ".wrap_words" do
    def context_for(width, size: 7)
      described_class::Context.new(classifier: nil, bounds_width: width,
                                   font_size: size, family: "Carlito")
    end

    it "returns the text unwrapped when it fits the usable width" do
      ctx = context_for(100)
      expect(described_class.wrap_words("FuelStation: LA_BAUnit", ctx, :bold))
        .to eq(["FuelStation: LA_BAUnit"])
    end

    it "wraps at a space when the full string exceeds width - 6" do
      ctx = context_for(100)
      expect(described_class.wrap_words("SU_PB2: LA_SpatialUnit", ctx, :bold))
        .to eq(["SU_PB2:", "LA_SpatialUnit"])
    end

    it "breaks qualified names after ::" do
      ctx = context_for(230, size: 9)
      lines = described_class.wrap_words(
        "Content information::MD_FeatureCatalogueDescription", ctx, :bold
      )
      expect(lines).to eq(["Content information::", "MD_FeatureCatalogueDescription"])
    end

    it "drops only the synthetic separator at each line start" do
      ctx = context_for(1)
      expect(described_class.wrap_words("a b::c d", ctx, :bold))
        .to eq(["a", "b::", "c", "d"])
    end
  end

  describe "provider chain extensibility (OCP)" do
    it "supports adding a new provider without modifying existing ones" do
      extra_provider = Module.new do
        def self.call(_context)
          [["<INJECTED>", :bold]]
        end
      end

      # Verify the chain is configurable via PROVIDERS constant.
      # In production code, you'd reopen the module and append.
      original = described_class::PROVIDERS
      begin
        described_class.const_set(:PROVIDERS, original + [extra_provider])
        klass = Ea::Model::Klass.new(name: "Y")
        lines = described_class.for(klass, diagram_package_id: nil)
        expect(lines).to include(["<INJECTED>", :bold])
      ensure
        described_class.const_set(:PROVIDERS, original)
      end
    end
  end
end
