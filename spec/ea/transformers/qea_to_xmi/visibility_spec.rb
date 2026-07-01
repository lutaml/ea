# frozen_string_literal: true

require "spec_helper"
require "ea/transformers/qea_to_xmi"

RSpec.describe Ea::Transformers::QeaToXmi::Visibility do
  describe ".from_scope" do
    it "maps 0 to 'public'" do
      expect(described_class.from_scope(0)).to eq("public")
    end

    it "maps 1 to 'private'" do
      expect(described_class.from_scope(1)).to eq("private")
    end

    it "maps 2 to 'protected'" do
      expect(described_class.from_scope(2)).to eq("protected")
    end

    it "maps 3 to 'package'" do
      expect(described_class.from_scope(3)).to eq("package")
    end

    it "accepts string-encoded integers" do
      expect(described_class.from_scope("1")).to eq("private")
    end

    it "returns nil for nil" do
      expect(described_class.from_scope(nil)).to be_nil
    end

    it "returns nil for empty string" do
      expect(described_class.from_scope("")).to be_nil
    end

    it "returns nil for unrecognised codes" do
      expect(described_class.from_scope(99)).to be_nil
    end
  end

  describe ".aggregation_from_containment" do
    it "maps 0 to nil (no aggregation)" do
      expect(described_class.aggregation_from_containment(0)).to be_nil
    end

    it "maps 1 to 'shared'" do
      expect(described_class.aggregation_from_containment(1)).to eq("shared")
    end

    it "maps 2 to 'composite'" do
      expect(described_class.aggregation_from_containment(2)).to eq("composite")
    end

    it "accepts string-encoded integers" do
      expect(described_class.aggregation_from_containment("2")).to eq("composite")
    end

    it "returns nil for nil" do
      expect(described_class.aggregation_from_containment(nil)).to be_nil
    end

    it "returns nil for unrecognised codes" do
      expect(described_class.aggregation_from_containment(99)).to be_nil
    end
  end

  describe ".boolean_from_flag" do
    it "maps '1' to 'true'" do
      expect(described_class.boolean_from_flag("1")).to eq("true")
    end

    it "maps 1 (integer) to 'true'" do
      expect(described_class.boolean_from_flag(1)).to eq("true")
    end

    it "maps '0' to 'false'" do
      expect(described_class.boolean_from_flag("0")).to eq("false")
    end

    it "maps 0 (integer) to 'false'" do
      expect(described_class.boolean_from_flag(0)).to eq("false")
    end

    it "returns nil for nil" do
      expect(described_class.boolean_from_flag(nil)).to be_nil
    end

    it "returns nil for empty string" do
      expect(described_class.boolean_from_flag("")).to be_nil
    end
  end
end
