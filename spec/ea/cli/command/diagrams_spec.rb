# frozen_string_literal: true

require "spec_helper"
require "ea/cli"

RSpec.describe Ea::Cli::Command::Diagrams do
  let(:qea_path) { fixtures_path("basic.qea") }
  let(:xmi_path) { fixtures_path("basic.xmi") }
  let(:lur_path) { fixtures_path("basic_test.lur") }

  describe "list action" do
    it "lists diagram names with types and GUIDs" do
      output = capture_stdout do
        described_class.new(action: "list", file: qea_path, format: "table").call
      end
      expect(output).to include("name")
      expect(output).to include("type")
      expect(output).to include("guid")
    end

    it "raises FileNotFound for missing files" do
      expect {
        described_class.new(action: "list", file: "/no/such.qea").call
      }.to raise_error(Ea::Cli::FileNotFound)
    end
  end

  describe "extract action" do
    # `extract` accepts any supported input format (QEA, XMI, LUR).
    # The .lur-only restriction was lifted — see TODO.next/40.

    it "extracts a diagram from a QEA file (TODO 40)" do
      out_path = "/tmp/ea_diag_qea_spec.svg"
      begin
        described_class.new(
          action: "extract",
          file: qea_path,
          name: "Starter Object Diagram",
          output: out_path,
        ).call
        expect(File.exist?(out_path)).to be(true)
        expect(File.size(out_path)).to be > 500
      ensure
        FileUtils.rm_f(out_path)
      end
    end

    it "extracts a diagram from an XMI file" do
      out_path = "/tmp/ea_diag_xmi_spec.svg"
      begin
        described_class.new(
          action: "extract",
          file: xmi_path,
          name: "Starter Object Diagram",
          output: out_path,
        ).call
        expect(File.exist?(out_path)).to be(true)
        expect(File.size(out_path)).to be > 500
      ensure
        FileUtils.rm_f(out_path)
      end
    end
  end

  describe "unknown action" do
    it "raises UnknownAction" do
      expect {
        described_class.new(action: "bogus", file: qea_path).call
      }.to raise_error(Ea::Cli::UnknownAction, /bogus/)
    end
  end

  describe "missing name on extract" do
    it "raises Cli::Error" do
      # No name passed → options[:name] is nil → Cli::Error
      expect {
        described_class.new(action: "extract", file: qea_path).call
      }.to raise_error(Ea::Cli::Error, /missing required NAME/)
    end
  end
end
