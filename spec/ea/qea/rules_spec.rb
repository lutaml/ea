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

RSpec.describe Ea::Qea::Rules::Generalization do
  let(:connectors) do
    [
      Ea::Qea::Models::EaConnector.new(
        connector_id: 1, start_object_id: 10, end_object_id: 20,
        connector_type: "Generalization"
      ),
      Ea::Qea::Models::EaConnector.new(
        connector_id: 2, start_object_id: 20, end_object_id: 10,
        connector_type: "Generalization"
      ),
      Ea::Qea::Models::EaConnector.new(
        connector_id: 3, start_object_id: 10, end_object_id: 30,
        connector_type: "Association"
      )
    ]
  end

  describe ".connector_for" do
    it "finds the child→parent generalization from the child side" do
      expect(described_class.connector_for(10, connectors).connector_id).to eq(1)
    end

    it "returns nil when the object is only a parent" do
      expect(described_class.connector_for(30, connectors)).to be_nil
    end

    it "returns nil for nil object id" do
      expect(described_class.connector_for(nil, connectors)).to be_nil
    end
  end

  describe ".connectors_from" do
    it "returns only the generalization connectors originating at the child" do
      expect(described_class.connectors_from(10, connectors).map(&:connector_id))
        .to eq([1])
    end

    it "returns [] for nil object id" do
      expect(described_class.connectors_from(nil, connectors)).to eq([])
    end
  end
end
