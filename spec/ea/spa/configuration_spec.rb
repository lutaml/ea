# frozen_string_literal: true

require "spec_helper"
require "ea"
require "tmpdir"

RSpec.describe Ea::Spa::Configuration do
  describe ".load" do
    it "returns nil for nil path" do
      expect(described_class.load(nil)).to be_nil
    end

    it "raises ArgumentError for missing file" do
      expect {
        described_class.load("/tmp/does-not-exist-#{Time.now.to_i}.yml")
      }.to raise_error(ArgumentError, /SPA config not found/)
    end

    it "parses YAML into a Configuration" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "config.yml")
        File.write(path, <<~YAML)
          metadata:
            title: Spec Title
            version: "1.0"
          ui:
            title: UI Title
        YAML
        config = described_class.load(path)
        expect(config.metadata_override[:title]).to eq("Spec Title")
        expect(config.ui["title"]).to eq("UI Title")
      end
    end
  end

  describe "#apply_to_metadata" do
    let(:model_metadata) do
      Ea::Model::Metadata.new(
        title: "Original",
        source_format: "qea",
        source_tool: "EA",
      )
    end

    it "overrides fields present in config" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "config.yml")
        File.write(path, "metadata:\n  title: Override\n")
        config = described_class.load(path)
        merged = config.apply_to_metadata(model_metadata)

        expect(merged.title).to eq("Override")
        expect(merged.source_format).to eq("qea")
      end
    end

    it "leaves the original metadata unchanged" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "config.yml")
        File.write(path, "metadata:\n  title: Override\n")
        config = described_class.load(path)
        config.apply_to_metadata(model_metadata)

        expect(model_metadata.title).to eq("Original")
      end
    end
  end

  describe "#view_extras" do
    it "excludes empty sections" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "config.yml")
        File.write(path, "metadata:\n  title: T\n")
        config = described_class.load(path)
        expect(config.view_extras).to eq({})
      end
    end

    it "includes ui and appearance when present" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "config.yml")
        File.write(path, <<~YAML)
          metadata:
            title: T
          ui:
            title: UI
          appearance:
            logos: {}
        YAML
        config = described_class.load(path)
        expect(config.view_extras.keys).to contain_exactly("ui", "appearance")
      end
    end
  end
end
