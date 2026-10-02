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
    it "always returns the plain name (qualification comes from the pipeline)" do
      klass = Ea::Model::Klass.new(id: "K", name: "X",
                                     qualified_name: "pkg::X")
      expect(described_class.display_name(klass, nil)).to eq("X")
      expect(described_class.display_name(klass, "PK1")).to eq("X")
    end
  end

  describe "foreign-package qualification" do
    it "prepends the owning package name for foreign elements" do
      klass = Ea::Model::Klass.new(id: "K", name: "CV_GridValueCell")
      lines = described_class.for(klass, foreign_package_name: "Quadrilateral Grid")
      expect(lines).to eq([["Quadrilateral Grid::CV_GridValueCell", :bold]])
    end

    it "wraps the qualified name when it exceeds the bounds width" do
      klass = Ea::Model::Klass.new(id: "K", name: "CV_SequenceType")
      lines = described_class.for(klass, foreign_package_name: "Quadrilateral Grid",
                                            bounds_width: 118, font_size: 7,
                                            family: "Carlito")
      expect(lines).to eq([["Quadrilateral Grid::", :bold], ["CV_SequenceType", :bold]])
    end

    it "keeps a fitting qualified name on one line" do
      klass = Ea::Model::Klass.new(id: "K", name: "CV_GridPoint")
      lines = described_class.for(klass, foreign_package_name: "Quadrilateral Grid",
                                            bounds_width: 174, font_size: 7,
                                            family: "Carlito")
      expect(lines).to eq([["Quadrilateral Grid::CV_GridPoint", :bold]])
    end

    it "qualifies abstract classes with the bold-italic style" do
      klass = Ea::Model::Klass.new(id: "K", name: "CV_ValueObject", is_abstract: true)
      lines = described_class.for(klass, foreign_package_name: "Coverage Core")
      expect(lines).to eq([["Coverage Core::CV_ValueObject", :bold_italic]])
    end

    it "renders the plain name when no foreign package is given" do
      klass = Ea::Model::Klass.new(id: "K", name: "IF_QuadGriddedData")
      lines = described_class.for(klass, foreign_package_name: nil)
      expect(lines).to eq([["IF_QuadGriddedData", :bold]])
    end
  end
end
