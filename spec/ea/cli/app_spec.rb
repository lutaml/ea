# frozen_string_literal: true

require "spec_helper"
require "ea/cli"

RSpec.describe Ea::Cli::App do
  describe "#version" do
    it "prints the gem version" do
      output = capture_stdout { described_class.start(%w[version]) }
      expect(output.strip).to eq(Ea::VERSION)
    end
  end

  describe "#help" do
    it "lists all commands" do
      output = capture_stdout { described_class.start(%w[help]) }
      %w[list diagrams validate stats parse convert version].each do |cmd|
        expect(output).to include(cmd)
      end
    end
  end

  describe "output flag short alias" do
    let(:qea_fixture) { fixtures_path("basic.qea") }
    let(:xmi_fixture) { fixtures_path("basic.xmi") }

    after do
      FileUtils.rm_f([@spa_out, @convert_out].compact)
    end

    it "exposes -o as alias for --output on the spa command" do
      output = capture_stdout { described_class.start(%W[help spa]) }
      expect(output).to match(/-o,\s+\[--output=OUTPUT\]/)
    end

    it "exposes -o as alias for --output on the convert command" do
      output = capture_stdout { described_class.start(%w[help convert]) }
      expect(output).to match(/-o,\s+\[--output=OUTPUT\]/)
    end

    it "exposes -o as alias for --output on the diagrams command" do
      output = capture_stdout { described_class.start(%w[help diagrams]) }
      expect(output).to match(/-o,\s+\[--output=OUTPUT\]/)
    end

    it "accepts -o PATH on the spa command end-to-end" do
      @spa_out = "/tmp/ea_cli_app_spa_short_alias_spec.html"
      capture_stdout do
        described_class.start(%W[spa #{qea_fixture} -o #{@spa_out}])
      end
      expect(File.exist?(@spa_out)).to be(true)
      expect(File.size(@spa_out)).to be > 50_000
    end

    it "accepts -o PATH on the convert command end-to-end" do
      @convert_out = "/tmp/ea_cli_app_convert_short_alias_spec.xmi"
      capture_stdout do
        described_class.start(%W[convert #{qea_fixture} --to xmi -o #{@convert_out}])
      end
      expect(File.exist?(@convert_out)).to be(true)
      expect(File.size(@convert_out)).to be > 1_000
    end
  end
end
