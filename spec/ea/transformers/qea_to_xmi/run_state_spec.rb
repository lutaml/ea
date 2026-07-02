# frozen_string_literal: true

require "spec_helper"
require "ea/transformers/qea_to_xmi"

RSpec.describe Ea::Transformers::QeaToXmi::RunState do
  describe ".parse" do
    it "returns empty array for nil" do
      expect(described_class.parse(nil)).to eq([])
    end

    it "returns empty array for empty string" do
      expect(described_class.parse("")).to eq([])
    end

    it "returns empty array for whitespace-only string" do
      expect(described_class.parse("   ")).to eq([])
    end

    it "parses a single @VAR block" do
      raw = "@VAR;Variable=name;Value=Alice;Op==;@ENDVAR;"
      result = described_class.parse(raw)
      expect(result.size).to eq(1)
      expect(result[0].variable).to eq("name")
      expect(result[0].value).to eq("Alice")
      expect(result[0].op).to eq("=")
    end

    it "parses multiple concatenated @VAR blocks" do
      raw = "@VAR;Variable=a;Value=1;Op==;@ENDVAR;@VAR;Variable=b;Value=2;Op==;@ENDVAR;"
      result = described_class.parse(raw)
      expect(result.size).to eq(2)
      expect(result.map(&:variable)).to eq(["a", "b"])
      expect(result.map(&:value)).to eq(["1", "2"])
    end

    it "parses real EA RunState from basic.qea (Object A)" do
      # 54 bytes — single variable
      raw = "@VAR;Variable=Variable A;Value=Value One;Op==;@ENDVAR;"
      result = described_class.parse(raw)
      expect(result.size).to eq(1)
      expect(result[0].variable).to eq("Variable A")
      expect(result[0].value).to eq("Value One")
    end

    it "parses real EA RunState from basic.qea (Object 03)" do
      # 114 bytes — two variables concatenated
      raw = "@VAR;Variable=attribute Two;Value=Value Two;Op==;@ENDVAR;@VAR;Variable=attribute One;Value=Value One;Op==;@ENDVAR;"
      result = described_class.parse(raw)
      expect(result.size).to eq(2)
      expect(result[0].variable).to eq("attribute Two")
      expect(result[1].variable).to eq("attribute One")
    end

    it "tolerates a trailing partial block without raising" do
      # Defensive: EA sometimes truncates large RunState blobs.
      raw = "@VAR;Variable=x;Value=1;Op==;@ENDVAR;@VAR;Variable=y;"
      result = described_class.parse(raw)
      expect(result.size).to eq(1)
      expect(result[0].variable).to eq("x")
    end

    it "returns empty array when no @VAR blocks are present" do
      expect(described_class.parse("random text without vars")).to eq([])
    end
  end

  describe "Binding#body" do
    it "prepends the operator character to the value (Sparx convention)" do
      binding = described_class::Binding.new("name", "Alice", "=")
      expect(binding.body).to eq("=Alice")
    end

    it "returns the value unchanged when op is empty" do
      binding = described_class::Binding.new("name", "Alice", "")
      expect(binding.body).to eq("Alice")
    end

    it "returns the value unchanged when op is nil" do
      binding = described_class::Binding.new("name", "Alice", nil)
      expect(binding.body).to eq("Alice")
    end

    it "uses only the first character of multi-character operators" do
      # EA's Op field sometimes carries the literal characters of the
      # comparison operator (`==`, `!=`, `<=`, `>=`). Sparx prepends
      # only the first character to the body value.
      binding = described_class::Binding.new("n", "v", "!=")
      expect(binding.body).to eq("!v")
    end
  end
end
