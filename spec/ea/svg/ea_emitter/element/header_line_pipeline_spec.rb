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
