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
    it "excludes empty ui/appearance sections but always emits diagrams.enabled" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "config.yml")
        File.write(path, "metadata:\n  title: T\n")
        config = described_class.load(path)
        expect(config.view_extras).to eq({ "diagrams" => { "enabled" => true } })
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
        expect(config.view_extras.keys).to contain_exactly("ui", "appearance", "diagrams")
      end
    end
  end
end

RSpec.describe Ea::Spa::Configuration, "#render_diagrams?" do
  it "defaults to true when config absent" do
    config = described_class.new(nil, {})
    expect(config.render_diagrams?).to be(true)
  end

  it "defaults to true when diagrams section absent" do
    config = described_class.new(nil, { "metadata" => { "title" => "X" } })
    expect(config.render_diagrams?).to be(true)
  end

  it "returns false when diagrams.enabled is false" do
    config = described_class.new(nil, { "diagrams" => { "enabled" => false } })
    expect(config.render_diagrams?).to be(false)
  end

  it "includes diagrams.enabled in view_extras so the frontend can hide UI" do
    config = described_class.new(nil, { "diagrams" => { "enabled" => false } })
    expect(config.view_extras["diagrams"]).to eq({ "enabled" => false })
  end
end

RSpec.describe Ea::Spa::Projector, "diagrams.enabled=false" do
  let(:document) do
    Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      packages: [Ea::Model::Package.new(id: "p1", name: "P")],
      classifiers: [Ea::Model::Klass.new(id: "c1", name: "C", package_id: "p1")],
      diagrams: [Ea::Model::Diagram.new(id: "d1", name: "D", package_id: "p1")]
    )
  end

  it "skips diagram shards when config disables them" do
    config = Ea::Spa::Configuration.new(nil, "diagrams" => { "enabled" => false })
    projector = Ea::Spa::Projector.new(document, configuration: config)
    shards = projector.each_shard.to_a
    expect(shards.map(&:kind)).to contain_exactly("class", "package")
    expect(shards.map(&:kind)).not_to include("diagram")
  end

  it "includes diagram shards when config enables them (default)" do
    projector = Ea::Spa::Projector.new(document)
    shards = projector.each_shard.to_a
    expect(shards.map(&:kind)).to include("diagram")
  end
end
