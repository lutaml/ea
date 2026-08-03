# frozen_string_literal: true

require "spec_helper"
require "ea"
require "ea/svg/ea_emitter/element/header_lines"

RSpec.describe Ea::Svg::EaEmitter::Element::HeaderLines do
  describe ".for" do
    it "returns just the bold class name for a plain Klass with no stereotype" do
      klass = Ea::Model::Klass.new(id: "K", name: "Widget")
      lines = described_class.for(klass)
      expect(lines).to eq([["Widget", :bold]])
    end

    it "returns italic-bold name for an abstract Klass" do
      klass = Ea::Model::Klass.new(id: "K", name: "Shape", is_abstract: true)
      lines = described_class.for(klass)
      expect(lines.last).to eq(["Shape", :bold_italic])
    end

    it "prepends the explicit stereotype when stereotype_refs present" do
      klass = Ea::Model::Klass.new(id: "K", name: "X")
      klass.stereotype_refs << "FeatureType"
      lines = described_class.for(klass)
      expect(lines).to eq([["«FeatureType»", :normal], ["X", :bold]])
    end

    it "prepends the off-canvas parent name as italic when provided" do
      klass = Ea::Model::Klass.new(id: "K", name: "Room")
      lines = described_class.for(klass, off_canvas_parent_name: "_CityObject")
      expect(lines.first).to eq(["_CityObject", :italic])
      expect(lines.last).to eq(["Room", :bold])
    end

    it "does not prepend parent line when off_canvas_parent_name is nil" do
      klass = Ea::Model::Klass.new(id: "K", name: "X")
      lines = described_class.for(klass, off_canvas_parent_name: nil)
      expect(lines.first).to eq(["X", :bold])
    end

    it "prefers UMLDI keyword over explicit stereotype" do
      klass = Ea::Model::Klass.new(id: "K", name: "X")
      klass.stereotype_refs << "FeatureType"
      lines = described_class.for(klass, umldi_keyword: "DataType")
      expect(lines.first).to eq(["«DataType»", :normal])
    end

    it "uses the fallback stereotype for Enumeration" do
      klass = Ea::Model::Enumeration.new(id: "E", name: "Color")
      lines = described_class.for(klass)
      expect(lines.first).to eq(["«enumeration»", :normal])
      expect(lines.last).to eq(["Color", :bold])
    end

    it "uses the fallback stereotype for DataType" do
      klass = Ea::Model::DataType.new(id: "D", name: "Measure")
      lines = described_class.for(klass)
      expect(lines.first).to eq(["«dataType»", :normal])
    end

    it "uses the fallback stereotype for PrimitiveType" do
      klass = Ea::Model::PrimitiveType.new(id: "P", name: "string")
      lines = described_class.for(klass)
      expect(lines.first).to eq(["«primitive»", :normal])
    end

    it "uses the fallback stereotype for Interface" do
      klass = Ea::Model::Interface.new(id: "I", name: "Renderable")
      lines = described_class.for(klass)
      expect(lines.first).to eq(["«interface»", :normal])
    end

    it "uses the fallback stereotype for Signal" do
      klass = Ea::Model::Signal.new(id: "S", name: "Click")
      lines = described_class.for(klass)
      expect(lines.first).to eq(["«signal»", :normal])
    end

    it "renders no stereotype for plain Package" do
      pkg = Ea::Model::Package.new(id: "P", name: "mypkg")
      lines = described_class.for(pkg)
      expect(lines).to eq([["mypkg", :bold]])
    end

    it "renders no stereotype for plain Note" do
      note = Ea::Model::Note.new(id: "N", name: "note")
      lines = described_class.for(note)
      expect(lines).to eq([["note", :bold]])
    end
  end

  describe ".display_name with package scoping" do
    it "returns the qualified name when diagram_package_id is nil" do
      klass = Ea::Model::Klass.new(id: "K", name: "X",
                                     qualified_name: "pkg::X")
      expect(described_class.display_name(klass, nil)).to eq("pkg::X")
    end

    it "returns the simple name when the qualifier matches the diagram package" do
      klass = Ea::Model::Klass.new(id: "K", name: "pkg::X",
                                     qualified_name: "pkg::X",
                                     package_id: "PK1",
                                     package_name: "pkg")
      expect(described_class.display_name(klass, "PK1")).to eq("X")
    end

    it "keeps the qualified name when the classifier's package differs" do
      klass = Ea::Model::Klass.new(id: "K", name: "other::X",
                                     qualified_name: "other::X",
                                     package_id: "PK2",
                                     package_name: "other")
      expect(described_class.display_name(klass, "PK1")).to eq("other::X")
    end
  end
end
