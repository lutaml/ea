# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Svg::StereotypeColorResolver do
  describe "#fill_for" do
    it "looks up by lowercase stereotype name" do
      resolver = described_class.new(color_map: { "featuretype" => "#FFFFCC" })
      expect(resolver.fill_for("FeatureType")).to eq("#FFFFCC")
    end

    it "returns the default for unknown stereotypes" do
      resolver = described_class.new(color_map: {})
      expect(resolver.fill_for("UnknownThing")).to eq("#FFFFFF")
    end

    it "returns the default for nil" do
      resolver = described_class.new(color_map: {})
      expect(resolver.fill_for(nil)).to eq("#FFFFFF")
    end

    it "loads the default config from disk" do
      resolver = described_class.new
      expect(resolver.fill_for("FeatureType")).to eq("#FFFFCC")
      expect(resolver.fill_for("DataType")).to eq("#FFCCFF")
    end
  end

  describe ".default_map" do
    after { described_class.reset_default_map }

    it "memoizes the loaded YAML" do
      first = described_class.default_map
      second = described_class.default_map
      expect(first).to be(second)
    end
  end
end
