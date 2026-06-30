# frozen_string_literal: true

require "spec_helper"
require "ea/transformers/qea_to_xmi"

RSpec.describe Ea::Transformers::QeaToXmi::Cardinality do
  describe ".parse" do
    it "returns UML defaults for nil" do
      expect(described_class.parse(nil)).to eq(lower: "0", upper: "-1")
    end

    it "returns UML defaults for empty string" do
      expect(described_class.parse("")).to eq(lower: "0", upper: "-1")
    end

    it "returns UML defaults for whitespace-only string" do
      expect(described_class.parse("   ")).to eq(lower: "0", upper: "-1")
    end

    it "treats a single integer as both lower and upper" do
      expect(described_class.parse("1")).to eq(lower: "1", upper: "1")
    end

    it "parses a 0..1 range" do
      expect(described_class.parse("0..1")).to eq(lower: "0", upper: "1")
    end

    it "parses a 1..* range" do
      expect(described_class.parse("1..*")).to eq(lower: "1", upper: "-1")
    end

    it "parses a 0..* range" do
      expect(described_class.parse("0..*")).to eq(lower: "0", upper: "-1")
    end

    it "treats a bare '*' as 0..-1 (many, lower unspecified)" do
      # Bare * means "many" — lower bound defaults to 0 (UML
      # unspecified), upper is unlimited. Returning lower=-1 would be
      # invalid: LiteralInteger cannot hold -1.
      expect(described_class.parse("*")).to eq(lower: "0", upper: "-1")
    end

    it "strips surrounding whitespace" do
      expect(described_class.parse("  1..*  ")).to eq(lower: "1", upper: "-1")
    end

    it "parses the unbounded token" do
      result = described_class.parse("unbounded")
      expect(result[:upper]).to eq("-1")
    end
  end

  describe ".normalize_upper" do
    it "returns -1 for nil" do
      expect(described_class.normalize_upper(nil)).to eq("-1")
    end

    it "returns -1 for empty string" do
      expect(described_class.normalize_upper("")).to eq("-1")
    end

    it "returns -1 for *" do
      expect(described_class.normalize_upper("*")).to eq("-1")
    end

    it "returns -1 for *-1" do
      expect(described_class.normalize_upper("*-1")).to eq("-1")
    end

    it "returns -1 for unbounded" do
      expect(described_class.normalize_upper("unbounded")).to eq("-1")
    end

    it "returns -1 for UNBOUNDED (case insensitive)" do
      expect(described_class.normalize_upper("UNBOUNDED")).to eq("-1")
    end

    it "returns the token unchanged for numeric values" do
      expect(described_class.normalize_upper("5")).to eq("5")
    end

    it "returns the token unchanged for negative numbers" do
      expect(described_class.normalize_upper("-1")).to eq("-1")
    end
  end

  describe ".normalize_lower" do
    it "returns 0 for nil" do
      expect(described_class.normalize_lower(nil)).to eq("0")
    end

    it "returns 0 for empty string" do
      expect(described_class.normalize_lower("")).to eq("0")
    end

    it "returns 0 for whitespace-only string" do
      expect(described_class.normalize_lower("   ")).to eq("0")
    end

    it "returns the token unchanged for numeric values" do
      expect(described_class.normalize_lower("1")).to eq("1")
    end

    it "returns the token unchanged for zero" do
      expect(described_class.normalize_lower("0")).to eq("0")
    end
  end

  describe "defaults constants" do
    it "exposes DEFAULT_LOWER" do
      expect(described_class::DEFAULT_LOWER).to eq("0")
    end

    it "exposes DEFAULT_UPPER" do
      expect(described_class::DEFAULT_UPPER).to eq("-1")
    end
  end
end
