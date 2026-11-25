# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Qea::Rules do
  describe "Visibility.canonical" do
    it "maps EA scope text case-insensitively" do
      expect(Ea::Qea::Rules::Visibility.canonical("Public")).to eq("public")
      expect(Ea::Qea::Rules::Visibility.canonical("PRIVATE")).to eq("private")
      expect(Ea::Qea::Rules::Visibility.canonical(:package)).to eq("package")
    end

    it "maps 'Package' scope to the package token" do
      expect(Ea::Qea::Rules::Visibility.canonical("Package")).to eq("package")
    end

    it "defaults blank and unknown values to public" do
      expect(Ea::Qea::Rules::Visibility.canonical(nil)).to eq("public")
      expect(Ea::Qea::Rules::Visibility.canonical("")).to eq("public")
      expect(Ea::Qea::Rules::Visibility.canonical("weird")).to eq("public")
    end

    it "builds the capitalized extension wire form" do
      expect(Ea::Qea::Rules::Visibility.extension_scope("private")).to eq("Private")
      expect(Ea::Qea::Rules::Visibility.extension_scope(nil)).to eq("Public")
    end
  end

  describe "Cardinality.parse" do
    it "parses ranges" do
      expect(Ea::Qea::Rules::Cardinality.parse("0..1")).to eq(min: "0", max: "1")
      expect(Ea::Qea::Rules::Cardinality.parse("1..*")).to eq(min: "1", max: "*")
    end

    it "parses bare values as N..N" do
      expect(Ea::Qea::Rules::Cardinality.parse("2")).to eq(min: "2", max: "2")
    end

    it "parses bare '*' as unbounded 0..*" do
      expect(Ea::Qea::Rules::Cardinality.parse("*")).to eq(min: "0", max: "*")
      expect(Ea::Qea::Rules::Cardinality.parse("unbounded")).to eq(min: "0", max: "*")
    end

    it "defaults nil and blank to 0..*" do
      expect(Ea::Qea::Rules::Cardinality.parse(nil)).to eq(min: "0", max: "*")
      expect(Ea::Qea::Rules::Cardinality.parse("")).to eq(min: "0", max: "*")
    end

    it "normalizes bounds" do
      expect(Ea::Qea::Rules::Cardinality.normalize_min("*")).to eq("0")
      expect(Ea::Qea::Rules::Cardinality.normalize_max(nil)).to eq("*")
      expect(Ea::Qea::Rules::Cardinality.normalize_min("2")).to eq("2")
    end
  end

  describe "EnumLiteral.enumeration?" do
    it "detects the Enumeration object type" do
      expect(Ea::Qea::Rules::EnumLiteral.enumeration?("Enumeration", nil)).to be true
      expect(Ea::Qea::Rules::EnumLiteral.enumeration?("Class", nil)).to be false
    end

    it "detects the enumeration stereotype case-insensitively" do
      expect(Ea::Qea::Rules::EnumLiteral.enumeration?("Class", "Enumeration")).to be true
      expect(Ea::Qea::Rules::EnumLiteral.enumeration?("Class", "enumeration")).to be true
      expect(Ea::Qea::Rules::EnumLiteral.enumeration?("Class", nil)).to be false
    end
  end
end
