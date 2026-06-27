# frozen_string_literal: true

require "spec_helper"
require "ea/cli"

RSpec.describe Ea::Cli::Command::List do
  let(:qea_path) { fixtures_path("basic.qea") }

  describe "summary mode (no --type)" do
    it "lists element counts per kind" do
      output = capture_stdout do
        described_class.new(file: qea_path, format: "table").call
      end
      expect(output).to include("classes")
      expect(output).to include("packages")
      expect(output).to include("diagrams")
      expect(output).to include("connectors")
    end
  end

  describe "--type class" do
    it "lists class names with GUIDs" do
      output = capture_stdout do
        described_class.new(file: qea_path, format: "table", type: "class").call
      end
      expect(output).to include("Class A")
      expect(output).to include("{") # GUID marker
    end
  end

  describe "--type package" do
    it "lists package names with GUIDs" do
      output = capture_stdout do
        described_class.new(file: qea_path, format: "table", type: "package").call
      end
      expect(output).to include("Model")
    end
  end

  describe "invalid --type" do
    it "raises a Cli::Error naming valid types" do
      expect {
        described_class.new(file: qea_path, type: "bogus").call
      }.to raise_error(Ea::Cli::Error, /Unknown type 'bogus'/)
    end
  end

  describe "missing file" do
    it "raises FileNotFound" do
      expect {
        described_class.new(file: "/does/not/exist.qea").call
      }.to raise_error(Ea::Cli::FileNotFound)
    end
  end
end
