# frozen_string_literal: true

require "spec_helper"
require "ea/cli"

RSpec.describe Ea::Cli::Command::Diagrams do
  let(:qea_path) { fixtures_path("basic.qea") }
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

  describe "extract action on a QEA file" do
    it "raises UnsupportedFormat (extract requires .lur)" do
      expect {
        described_class.new(
          action: "extract",
          file: qea_path,
          name: "any",
        ).call
      }.to raise_error(Ea::Cli::UnsupportedFormat, /\.lur/)
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
      expect {
        described_class.new(action: "extract", file: lur_path).call
      }.to raise_error(Ea::Cli::Error, /missing required NAME/)
    end
  end
end
