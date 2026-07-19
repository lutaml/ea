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
    it "writes one HTML file with embedded JSON" do
      Dir.mktmpdir do |dir|
        out = File.join(dir, "spa.html")
        described_class.new(out).render(projector)
        contents = File.read(out)

        expect(contents).to include("<!DOCTYPE html>")
        expect(contents).to include("window.__SPA_DATA__")
        expect(contents).to include("\"name\":\"A\"")
      end
    end
  end

  describe Ea::Spa::Output::ShardedMultiFileStrategy do
    it "writes skeleton.json, search.json, and one shard per entity" do
      Dir.mktmpdir do |dir|
        described_class.new(dir).render(projector)

        expect(File.exist?(File.join(dir, "skeleton.json"))).to be(true)
        expect(File.exist?(File.join(dir, "search.json"))).to be(true)
        expect(File.exist?(File.join(dir, "index.html"))).to be(true)

        class_shard = File.join(dir, "data", "classes", "c1.json")
        pkg_shard = File.join(dir, "data", "packages", "p1.json")
        expect(File.exist?(class_shard)).to be(true)
        expect(File.exist?(pkg_shard)).to be(true)

        payload = JSON.parse(File.read(class_shard))
        expect(payload["kind"]).to eq("class")
        expect(payload["payload"]["name"]).to eq("A")
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
