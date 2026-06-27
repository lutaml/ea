# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "ea/cli"

RSpec.describe Ea::Cli::Command::Convert do
  let(:qea_path) { fixtures_path("basic.qea") }
  let(:temp_dir) { Dir.mktmpdir }
  after { FileUtils.remove_entry(temp_dir) if Dir.exist?(temp_dir) }

  describe "QEA → XMI" do
    it "writes well-formed XMI to the requested output path" do
      out_path = File.join(temp_dir, "out.xmi")
      capture_stdout do
        described_class.new(
          file: qea_path,
          to: "xmi",
          output: out_path,
          format: "table",
        ).call
      end

      expect(File.exist?(out_path)).to be(true)
      xml = File.read(out_path)
      expect(xml).to include("<xmi:XMI")
      expect(xml).to include("<uml:Model")
      expect(xml).to include("EA_Model")
    end

    it "produces XML parseable by the XMI parser" do
      require "xmi"
      out_path = File.join(temp_dir, "out.xmi")
      capture_stdout do
        described_class.new(
          file: qea_path,
          to: "xmi",
          output: out_path,
        ).call
      end
      parsed = ::Xmi::Sparx::Root.parse_xml(File.read(out_path))
      expect(parsed).to be_a(::Xmi::Sparx::Root)
    end
  end

  describe "missing --to" do
    it "raises Cli::Error" do
      expect {
        described_class.new(file: qea_path).call
      }.to raise_error(Ea::Cli::Error, /missing required --to/)
    end
  end

  describe "unsupported --to" do
    it "raises Cli::Error listing valid targets" do
      expect {
        described_class.new(file: qea_path, to: "bogus").call
      }.to raise_error(Ea::Cli::Error, /Unsupported target 'bogus'/)
    end
  end

  describe "unsupported input format" do
    let(:temp_path) { File.join(temp_dir, "weird.xml") }

    before do
      File.write(temp_path, "<not really/>")
    end

    it "raises UnsupportedFormat for non-qea input" do
      expect {
        described_class.new(file: temp_path, to: "xmi").call
      }.to raise_error(Ea::Cli::UnsupportedFormat, /supported inputs: qea/)
    end
  end
end
