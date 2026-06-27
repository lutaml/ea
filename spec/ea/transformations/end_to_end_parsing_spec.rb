# frozen_string_literal: true

require "spec_helper"

RSpec.describe "End-to-end parsing via Transformations", :integration do
  let(:qea_path) do
    File.expand_path("../../../examples/qea/basic.qea", __dir__)
  end

  let(:xmi_path) do
    File.expand_path("../../../../../lutaml-uml/examples/xmi/basic.xmi",
                     __dir__)
  end

  describe "QEA parsing via Transformations.parse" do
    before do
      skip "QEA fixture not found" unless File.exist?(qea_path)
    end

    it "dispatches to QeaParser and returns a UML Document" do
      result = Ea::Transformations.parse(qea_path)
      expect(result).to be_a(Lutaml::Uml::Document)
    end

    it "populates packages from the QEA file" do
      result = Ea::Transformations.parse(qea_path)
      expect(result.packages).to be_an(Array)
    end

    it "populates associations from the QEA file" do
      result = Ea::Transformations.parse(qea_path)
      expect(result.associations).to be_an(Array)
    end
  end

  describe "XMI parsing via Transformations.parse" do
    before do
      skip "XMI fixture not found" unless File.exist?(xmi_path)
    end

    it "dispatches to XmiParser and returns a UML Document" do
      result = Ea::Transformations.parse(xmi_path)
      expect(result).to be_a(Lutaml::Uml::Document)
    end

    it "populates packages from the XMI file" do
      result = Ea::Transformations.parse(xmi_path)
      expect(result.packages).not_to be_empty
    end
  end

  describe "format detection" do
    it "detects .qea files" do
      expect(Ea::Transformations.supports_file?("model.qea")).to be true
    end

    it "detects .xmi files" do
      expect(Ea::Transformations.supports_file?("model.xmi")).to be true
    end

    it "detects .xml files via XMI parser" do
      parser = Ea::Transformations::Parsers::XmiParser.new
      expect(parser.can_parse?("model.xml")).to be true
    end

    it "rejects unknown extensions" do
      expect(Ea::Transformations.supports_file?("model.txt")).to be false
    end
  end
end
