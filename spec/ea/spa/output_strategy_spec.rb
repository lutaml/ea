# frozen_string_literal: true

require "spec_helper"
require "ea"
require "tmpdir"

RSpec.describe Ea::Spa::Output do
  let(:document) do
    Ea::Model::Document.new(
      metadata: Ea::Model::Metadata.new(title: "T", source_format: "qea"),
      packages: [Ea::Model::Package.new(id: "p1", name: "Root")],
      classifiers: [
        Ea::Model::Klass.new(id: "c1", name: "A", package_id: "p1",
                             qualified_name: "Root::A")
      ]
    )
  end

  let(:projector) { Ea::Spa::Projector.new(document) }

  describe Ea::Spa::Output::SingleFileStrategy do
    it "writes one HTML file with embedded JSON, JS, and CSS" do
      Dir.mktmpdir do |dir|
        out = File.join(dir, "spa.html")
        described_class.new(out).render(projector)
        contents = File.read(out)

        expect(contents).to include("<!DOCTYPE html>")
        expect(contents).to include("<style>")
        expect(contents).to include("window.__SPA_DATA__")
        expect(contents).to include('"name":"A"')
        # The Vue IIFE bundle must be inlined so the SPA can mount
        # without external dependencies.
        expect(contents).to include("createApp")
      end
    end
  end

  describe Ea::Spa::Output::ShardedMultiFileStrategy do
    it "writes skeleton, search, shards, app.js, style.css, and a shell that references them" do
      Dir.mktmpdir do |dir|
        described_class.new(dir).render(projector)

        # Data files
        expect(File.exist?(File.join(dir, "skeleton.json"))).to be(true)
        expect(File.exist?(File.join(dir, "search.json"))).to be(true)

        # Shards
        class_shard = File.join(dir, "data", "classes", "c1.json")
        pkg_shard = File.join(dir, "data", "packages", "p1.json")
        expect(File.exist?(class_shard)).to be(true)
        expect(File.exist?(pkg_shard)).to be(true)
        payload = JSON.parse(File.read(class_shard))
        expect(payload["kind"]).to eq("class")
        expect(payload["payload"]["name"]).to eq("A")

        # Frontend bundle must ship alongside the data so the shell
        # can render without reaching outside the output directory.
        expect(File.exist?(File.join(dir, "app.js"))).to be(true)
        expect(File.exist?(File.join(dir, "style.css"))).to be(true)

        # Shell wires the assets together.
        index = File.read(File.join(dir, "index.html"))
        expect(index).to include('href="style.css"')
        expect(index).to include('src="app.js"')
        expect(index).to include("window.__SPA_SKELETON_URL__")
        expect(index).to include("window.__SPA_SHARD_BASE__")
      end
    end
  end

  describe Ea::Spa::Generator do
    it "dispatches to SingleFileStrategy when mode is :single_file" do
      Dir.mktmpdir do |dir|
        out = File.join(dir, "spa.html")
        described_class.new(document, output: out, mode: :single_file).generate
        expect(File.exist?(out)).to be(true)
      end
    end

    it "dispatches to ShardedMultiFileStrategy when mode is :sharded" do
      Dir.mktmpdir do |dir|
        described_class.new(document, output: dir, mode: :sharded).generate
        expect(File.exist?(File.join(dir, "skeleton.json"))).to be(true)
      end
    end

    it "raises on unknown mode" do
      expect do
        described_class.new(document, output: "/tmp/x",
                                      mode: :bogus).generate
      end.to raise_error(ArgumentError, /Unknown SPA mode/)
    end

    it "defaults to single_file mode when mode is omitted" do
      Dir.mktmpdir do |dir|
        out = File.join(dir, "spa.html")
        described_class.new(document, output: out).generate
        expect(File.exist?(out)).to be(true)
      end
    end
  end
end
