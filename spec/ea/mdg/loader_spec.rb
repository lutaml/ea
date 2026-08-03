# frozen_string: true

require "spec_helper"
require "ea"
require "ea/mdg"
require "fileutils"

RSpec.describe Ea::Mdg::Loader do
  let(:mdg_dir) { File.expand_path("../../fixtures/mdg", __dir__) }

  let(:mdg_technology_xml) do
    <<~XML
      <?xml version="1.0"?>
      <MDG.Technology version="1.0">
        <Documentation id="x" name="MDG Test" version="1.0" notes="test"/>
        <UMLProfiles>
          <UMLProfile profiletype="uml2">
            <Content>
              <Stereotypes>
                <Stereotype name="FeatureType" notes="A feature type.">
                  <AppliesTo>
                    <Apply type="Class"/>
                  </AppliesTo>
                  <TaggedValues>
                    <Tag name="noPropertyType" type="Boolean" default="false"/>
                  </TaggedValues>
                </Stereotype>
              </Stereotypes>
            </Content>
          </UMLProfile>
        </UMLProfiles>
      </MDG.Technology>
    XML
  end

  describe ".from_xml with MDG.Technology format" do
    it "extracts the technology name from <Documentation>" do
      doc = described_class.from_xml(mdg_technology_xml).document
      expect(doc.technology_name).to eq("MDG Test")
    end

    it "extracts stereotype definitions with tagged values" do
      doc = described_class.from_xml(mdg_technology_xml).document
      ft = doc.find_stereotype("FeatureType")
      expect(ft).not_to be_nil
      expect(ft.applies_to).to eq(["Class"])
      expect(ft.tagged_values.first.name).to eq("noPropertyType")
      expect(ft.tagged_values.first.default).to eq("false")
    end

    it "carries stereotype notes" do
      doc = described_class.from_xml(mdg_technology_xml).document
      ft = doc.find_stereotype("FeatureType")
      expect(ft.notes).to eq("A feature type.")
    end

    it "returns empty classifiers (MDG.Technology has no UML:Class)" do
      doc = described_class.from_xml(mdg_technology_xml).document
      expect(doc.classifiers).to eq([])
    end
  end

  describe ".from_path" do
    it "reads the CityGML fixture and parses stereotypes" do
      path = File.join(mdg_dir, "CityGML_MDG_Technology.xml")
      skip "fixture not available" unless File.exist?(path)
      doc = described_class.from_path(path).document
      expect(doc.technology_name).to eq("CityGML")
      expect(doc.stereotypes.size).to eq(11)
    end
  end

  describe "XMI format" do
    it "returns a placeholder Document for XMI root (full XMI support pending)" do
      xmi = %(<XMI xmi.version="1.1" xmlns:UML="omg.org/UML1.3"><XMI.content></XMI.content></XMI>)
      doc = described_class.from_xml(xmi).document
      expect(doc.technology_name).to eq("Unknown")
      expect(doc.classifiers).to eq([])
    end
  end
end
