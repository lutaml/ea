# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "securerandom"
require "ea"
require "ea/sources/xmi/umldi_keyword_extractor"

RSpec.describe Ea::Sources::Xmi::UmldiKeywordExtractor do
  let(:xmi_path) { File.join(Dir.tmpdir, "ea-umldi-#{SecureRandom.hex(4)}.xmi") }
  let(:extractor) { described_class.new(xmi_path) }

  describe "#keywords_for_diagram" do
    it "returns an empty hash when the file does not exist" do
      expect { described_class.new("/no/such/file.xmi").keywords_for_diagram("X") }
        .not_to raise_error
    end
  end

  describe "with a minimal Sparx XMI fixture" do
    before do
      File.write(xmi_path, <<~XML)
        <?xml version="1.0" encoding="UTF-8"?>
        <xmi:XMI xmlns:xmi="http://www.omg.org/spec/XMI/20131001"
                 xmlns:umldi="http://www.omg.org/spec/UML/20161101/UMLDI">
          <umldi:Diagram xmi:type="umldi:UMLClassDiagram"
                        xmi:id="DG1"
                        modelElement="PKG1">
            <ownedElement xmi:type="umldi:UMLClassifierShape"
                          xmi:id="SH1" modelElement="CLS1">
              <ownedElement xmi:type="umldi:UMLKeywordLabel" text="Type"/>
              <ownedElement xmi:type="umldi:UMLNameLabel" text="X"/>
            </ownedElement>
            <ownedElement xmi:type="umldi:UMLClassifierShape"
                          xmi:id="SH2" modelElement="CLS2">
              <ownedElement xmi:type="umldi:UMLKeywordLabel" text="FeatureType"/>
              <ownedElement xmi:type="umldi:UMLNameLabel" text="Y"/>
            </ownedElement>
          </umldi:Diagram>
        </xmi:XMI>
      XML
    end

    after { File.delete(xmi_path) if File.exist?(xmi_path) }

    it "indexes keywords by diagram and classifier id" do
      result = extractor.keywords_for_diagram("DG1")
      expect(result).to eq("CLS1" => "Type", "CLS2" => "FeatureType")
    end

    it "returns an empty hash for an unknown diagram" do
      expect(extractor.keywords_for_diagram("UNKNOWN")).to eq({})
    end
  end
end
