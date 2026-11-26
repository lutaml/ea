# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Rules::Namespacing do
  describe ".resolve_name_ns" do
    it "resolves the core namespace to the upper klass" do
      expect(described_class.resolve_name_ns("core", "GML_Schemas"))
        .to eq("GML_Schemas")
    end

    it "resolves the gml namespace to the upper klass" do
      expect(described_class.resolve_name_ns("gml", "GML_Schemas"))
        .to eq("GML_Schemas")
    end

    it "keeps any other namespace as-is" do
      expect(described_class.resolve_name_ns("xs", "GML_Schemas"))
        .to eq("xs")
    end

    it "falls back to the upper klass for a nil namespace" do
      expect(described_class.resolve_name_ns(nil, "GML_Schemas"))
        .to eq("GML_Schemas")
    end

    it "keeps an empty-string namespace (truthy, not a fallback)" do
      expect(described_class.resolve_name_ns("", "GML_Schemas")).to eq("")
    end

    it "returns nil when both namespace and upper klass are nil" do
      expect(described_class.resolve_name_ns(nil, nil)).to be_nil
    end
  end
end
