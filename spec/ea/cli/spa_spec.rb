# frozen_string_literal: true

require "spec_helper"
require "ea/cli"
require "tmpdir"

RSpec.describe "ea spa CLI command" do
  let(:qea_fixture) { fixtures_path("basic.qea") }

  describe "single-file mode" do
    it "produces an HTML file with embedded SPA data" do
      Dir.mktmpdir do |dir|
        out = File.join(dir, "out.html")
        Ea::Cli::App.start(
          ["spa", qea_fixture, "--output=#{out}", "--mode=single_file"]
        )
        contents = File.read(out)
        expect(contents).to include("<!DOCTYPE html>")
        expect(contents).to include("window.__SPA_DATA__")
      end
    end
  end

  describe "sharded mode" do
    it "produces a directory with skeleton.json, search.json, and shards" do
      Dir.mktmpdir do |dir|
        out = File.join(dir, "out.spa")
        Ea::Cli::App.start(
          ["spa", qea_fixture, "--output=#{out}", "--mode=sharded"]
        )
        expect(File.exist?(File.join(out, "skeleton.json"))).to be(true)
        expect(File.exist?(File.join(out, "search.json"))).to be(true)
        expect(File.exist?(File.join(out, "index.html"))).to be(true)
        expect(Dir.glob(File.join(out, "data", "**", "*.json"))).not_to be_empty
      end
    end

    it "default output path for sharded mode uses .spa suffix" do
      # Just verify the path resolution doesn't crash with default
      Dir.mktmpdir do |dir|
        copied = File.join(dir, "model.qea")
        FileUtils.cp(qea_fixture, copied)
        Ea::Cli::App.start(["spa", copied, "--mode=sharded"])
        expect(File.exist?(File.join(dir, "model.spa", "skeleton.json")))
          .to be(true)
      end
    end
  end

  describe "plateau model validation" do
    let(:plateau_v51) do
      "/Users/mulgogi/src/mn/plateau-model/20251010_current_plateau_v5.1.qea"
    end

    before { skip "plateau v5.1 not available" unless File.exist?(plateau_v51) }

    it "completes in under 60 seconds end-to-end" do
      Dir.mktmpdir do |dir|
        out = File.join(dir, "plateau.spa")
        start = Time.now
        Ea::Cli::App.start(
          ["spa", plateau_v51, "--output=#{out}", "--mode=sharded"]
        )
        elapsed = Time.now - start
        expect(elapsed).to be < 60, "expected < 60s, got #{elapsed.round(1)}s"
        expect(Dir.glob(File.join(out, "data", "**", "*.json")).size)
          .to be > 100
      end
    end
  end
end
