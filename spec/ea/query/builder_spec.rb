# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Query::Builder do
  let(:klass_a) do
    Struct.new(:object_type, :name, :package_id, :ea_guid).new("Class", "Building", 1, "{A}")
  end
  let(:klass_b) do
    Struct.new(:object_type, :name, :package_id, :ea_guid).new("Class", "Structure", 2, "{B}")
  end
  let(:iface) do
    Struct.new(:object_type, :name, :package_id, :ea_guid).new("Interface", "IRunnable", 1, "{C}")
  end
  let(:pkg1) do
    Struct.new(:package_id, :name).new(1, "Core")
  end
  let(:pkg2) do
    Struct.new(:package_id, :name).new(2, "Util")
  end

  let(:model) do
    Struct.new(:collections, keyword_init: true).new(
      collections: {
        objects: [klass_a, klass_b, iface],
        packages: [pkg1, pkg2],
      },
    )
  end

  describe "#classes" do
    it "filters to Class-type objects" do
      result = described_class.new(model).classes.call
      expect(result).to contain_exactly(klass_a, klass_b)
    end
  end

  describe "#interfaces" do
    it "filters to Interface-type objects" do
      result = described_class.new(model).interfaces.call
      expect(result).to eq([iface])
    end
  end

  describe "#packages" do
    it "switches to packages collection" do
      result = described_class.new(model).packages.call
      expect(result).to contain_exactly(pkg1, pkg2)
    end
  end

  describe "#with_type" do
    it "filters by EA object_type" do
      result = described_class.new(model).with_type("Class").call
      expect(result.size).to eq(2)
    end
  end

  describe "#in_package" do
    it "restricts to elements in the named package" do
      result = described_class.new(model).classes.in_package("Core").call
      expect(result).to eq([klass_a])
    end

    it "returns self when package not found" do
      builder = described_class.new(model).in_package("Nonexistent")
      expect(builder).to be_a(described_class)
    end
  end

  describe "#named" do
    it "filters by exact name match" do
      result = described_class.new(model).classes.named("Building").call
      expect(result).to eq([klass_a])
    end
  end

  describe "#name_contains" do
    it "filters by case-insensitive substring" do
      result = described_class.new(model).classes.name_contains("build").call
      expect(result).to eq([klass_a])
    end
  end

  describe "chaining" do
    it "combines multiple filters" do
      result = described_class.new(model)
               .classes
               .in_package("Core")
               .name_contains("build")
               .call
      expect(result).to eq([klass_a])
    end

    it "returns a new Builder each time (immutable)" do
      builder = described_class.new(model)
      chained = builder.classes
      expect(chained).not_to be(builder)
      expect(builder.filters).to be_empty
    end
  end

  describe "#each (Enumerable)" do
    it "iterates over filtered results" do
      names = described_class.new(model).classes.map(&:name)
      expect(names).to contain_exactly("Building", "Structure")
    end
  end
end
