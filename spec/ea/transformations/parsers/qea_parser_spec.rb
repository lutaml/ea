# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe Ea::Transformations::Parsers::QeaParser do
  let(:configuration) { Ea::Transformations::Configuration.new }
  let(:options) { {} }
  let(:parser) do
    described_class.new(configuration: configuration, options: options)
  end

  describe "#format_name" do
    it "returns QEA format name" do
      expect(parser.format_name).to eq("Enterprise Architect Database (QEA)")
    end
  end

  describe "#supported_extensions" do
    it "returns QEA file extensions" do
      expect(parser.supported_extensions).to include(".qea", ".eap", ".eapx")
    end
  end

  describe "#content_patterns" do
    it "returns QEA content detection patterns", :aggregate_failures do
      patterns = parser.content_patterns
      expect(patterns).to be_an(Array)
      expect(patterns).not_to be_empty

      sqlite_pattern = patterns.find { |p| p.source.include?("SQLite") }
      expect(sqlite_pattern).not_to be_nil
    end
  end

  describe "#priority" do
    it "returns high priority for QEA files" do
      expect(parser.priority).to eq(90)
    end
  end

  describe "#can_parse?" do
    it "returns true for .qea files" do
      expect(parser.can_parse?("test.qea")).to be true
    end

    it "returns true for .eap files" do
      expect(parser.can_parse?("test.eap")).to be true
    end

    it "returns true for .eapx files" do
      expect(parser.can_parse?("test.eapx")).to be true
    end

    it "returns false for unsupported extensions" do
      expect(parser.can_parse?("test.txt")).to be false
      expect(parser.can_parse?("test.xml")).to be false
    end

    it "detects SQLite content in files with unknown extensions" do
      file = Tempfile.new(["test", ".unknown"])
      file.write("SQLite format 3\x00")
      file.close
      expect(parser.can_parse?(file.path)).to be true
      file.unlink
    end

    it "rejects non-SQLite content" do
      file = Tempfile.new(["test", ".unknown"])
      file.write("Not a SQLite database")
      file.close
      expect(parser.can_parse?(file.path)).to be false
      file.unlink
    end
  end

  describe "#parse" do
    let(:basic_qea) do
      File.expand_path("../../../../examples/qea/basic.qea", __dir__)
    end

    context "with real QEA file", :integration do
      before do
        skip "QEA fixture not found" unless File.exist?(basic_qea)
      end

      it "parses a real QEA file to a UML Document" do
        result = parser.parse(basic_qea)
        expect(result).to be_a(Lutaml::Uml::Document)
      end

      it "populates packages from the database" do
        result = parser.parse(basic_qea)
        expect(result.packages).to be_an(Array)
      end

      it "populates associations from the database" do
        result = parser.parse(basic_qea)
        expect(result.associations).to be_an(Array)
      end
    end

    context "with file path validation" do
      it "raises error for non-existent file" do
        expect { parser.parse("nonexistent.qea") }.to raise_error(ArgumentError)
      end

      it "raises error for nil file path" do
        expect { parser.parse(nil) }.to raise_error(ArgumentError)
      end

      it "raises error for empty file path" do
        expect { parser.parse("") }.to raise_error(ArgumentError)
      end
    end

    context "with invalid file format" do
      it "raises parsing error for non-database file" do
        file = Tempfile.new(["text", ".qea"])
        file.write("This is not a QEA file")
        file.close
        expect { parser.parse(file.path) }.to raise_error(StandardError)
        file.unlink
      end
    end
  end

  describe "#validate_file!" do
    it "validates QEA file structure" do
      file = Tempfile.new(["sqlite", ".qea"])
      file.write("SQLite format 3\x00")
      file.write("\x00" * 100)
      file.close
      expect { parser.validate_file!(file.path) }.not_to raise_error
      file.unlink
    end
  end

  describe "#validate_output!" do
    it "validates output document structure" do
      doc = Lutaml::Uml::Document.new
      expect { parser.validate_output!(doc) }.not_to raise_error
    end

    it "raises error for nil output" do
      expect { parser.validate_output!(nil) }.to raise_error(ArgumentError)
    end
  end

  describe "statistics" do
    it "tracks QEA-specific metrics" do
      stats = parser.statistics
      expect(stats[:format]).to eq("Enterprise Architect Database (QEA)")
    end
  end
end
