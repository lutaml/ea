# frozen_string_literal: true

require "spec_helper"
require "ea/transformers"

RSpec.describe Ea::Transformers do
  let(:qea_path) { fixtures_path("basic.qea") }
  let(:document) { Ea::Qea.parse(qea_path) }

  describe ".uml_to_xmi" do
    it "returns a well-formed XMI XML string" do
      xml = described_class.uml_to_xmi(document)
      expect(xml).to start_with("<?xml")
      expect(xml).to include("<xmi:XMI")
      expect(xml).to include("</xmi:XMI>")
    end

    it "emits a single uml:Model named EA_Model" do
      xml = described_class.uml_to_xmi(document)
      expect(xml).to include(%(<uml:Model))
      expect(xml).to include(%(name="EA_Model"))
    end

    it "preserves xmi:id values from the parsed document" do
      xml = described_class.uml_to_xmi(document)
      expect(xml).to match(/EAPK_[0-9A-F]+_[0-9A-Fa-f]+/)
    end
  end
end

RSpec.describe Ea::Transformers::UmlToXmi::Transformer do
  let(:qea_path) { fixtures_path("basic.qea") }
  let(:document) { Ea::Qea.parse(qea_path) }

  describe "#serialize round-trip" do
    it "produces XML parseable by the xmi gem's Sparx parser" do
      require "xmi"
      xml = described_class.new(document).serialize
      parsed = ::Xmi::Sparx::Root.parse_xml(xml)
      expect(parsed).to be_a(::Xmi::Sparx::Root)
    end
  end
end

RSpec.describe Ea::Transformers::UmlToXmi::IdGenerator do
  it "returns MODEL_ID for #model_id" do
    expect(described_class.new.model_id).to eq("EAID_EA_MODEL")
  end

  it "reuses an element's existing xmi_id when set" do
    klass = Lutaml::Uml::UmlClass.new(xmi_id: "EAID_EXISTING_123")
    expect(described_class.new.eaid_for(klass)).to eq("EAID_EXISTING_123")
  end

  it "synthesizes a stable EAID when no xmi_id is set" do
    klass = Lutaml::Uml::UmlClass.new(name: "Untitled")
    gen = described_class.new
    id = gen.eaid_for(klass)
    expect(id).to start_with("EAID_")
    expect(gen.eaid_for(klass)).to eq(id)
  end
end
