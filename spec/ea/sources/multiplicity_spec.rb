# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Multiplicity do
  describe ".lower" do
    it "parses the lower bound" do
      expect(described_class.lower("0..*")).to eq(0)
      expect(described_class.lower("1..5")).to eq(1)
    end

    it "returns nil when unspecified" do
      expect(described_class.lower(nil)).to be_nil
      expect(described_class.lower("")).to be_nil
      expect(described_class.lower("   ")).to be_nil
    end

    it "returns nil for a non-numeric lower" do
      expect(described_class.lower("*")).to be_nil
    end
  end

  describe ".upper" do
    it "parses the upper bound" do
      expect(described_class.upper("1..5")).to eq(5)
    end

    it "maps * to -1" do
      expect(described_class.upper("0..*")).to eq(-1)
    end

    it "returns nil when unspecified" do
      expect(described_class.upper(nil)).to be_nil
      expect(described_class.upper("")).to be_nil
    end
  end

  describe ".raw" do
    it "returns stripped verbatim text" do
      expect(described_class.raw(" 0..* ")).to eq("0..*")
    end

    it "returns nil for blank text" do
      expect(described_class.raw("   ")).to be_nil
      expect(described_class.raw(nil)).to be_nil
    end
  end
end
