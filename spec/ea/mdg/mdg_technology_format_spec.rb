# frozen_string: true

require "spec_helper"
require "ea"
require "ea/mdg"

RSpec.describe "MDG.Technology format parsing" do
  let(:citygml_path) do
    File.expand_path("../../fixtures/mdg/CityGML_MDG_Technology.xml", __dir__)
  end
  let(:iso19103_path) do
    File.expand_path("../../fixtures/mdg/ISO19103MDG v1.0.0-beta.xml", __dir__)
  end

  describe "CityGML MDG" do
    let(:doc) { Ea::Mdg::Loader.from_path(citygml_path).document }

    it "extracts the technology name from <Documentation>" do
      expect(doc.technology_name).to eq("CityGML")
    end

    it "extracts all stereotype definitions" do
      expect(doc.stereotypes.size).to eq(11)
    end

    it "extracts FeatureType stereotype with its tagged values" do
      ft = doc.find_stereotype("FeatureType")
      expect(ft).not_to be_nil
      expect(ft.applies_to).to eq(["Class"])
      tag_names = ft.tagged_values.map(&:name)
      expect(tag_names).to include("noPropertyType", "byValuePropertyType",
                                   "isCollection", "gmlMixin")
    end

    it "extracts ApplicationSchema stereotype applying to Package" do
      app = doc.find_stereotype("ApplicationSchema")
      expect(app.applies_to).to eq(["Package"])
      expect(app.tagged_values.map(&:name)).to include("targetNamespace", "xmlns")
    end

    it "carries the stereotype's notes" do
      ft = doc.find_stereotype("FeatureType")
      expect(ft.notes).to include("feature type")
    end

    it "extracts TopLevelFeatureType generalization link" do
      top = doc.find_stereotype("TopLevelFeatureType")
      expect(top.generalizes).to eq("FeatureType")
      expect(top.base_stereotypes).to eq("FeatureType")
    end

    it "returns no classifiers (MDG.Technology has no UML:Class)" do
      expect(doc.classifiers).to eq([])
    end

    it "extracts tagged value defaults" do
      codelist = doc.find_stereotype("CodeList")
      as_dict = codelist.tagged_values.find { |t| t.name == "asDictionary" }
      expect(as_dict.default).to eq("true")
    end
  end

  describe "ISO 19103 MDG" do
    let(:doc) { Ea::Mdg::Loader.from_path(iso19103_path).document }

    it "extracts the technology name" do
      expect(doc.technology_name).to eq("ISO 19103 profile")
    end

    it "extracts stereotypes from the first UMLProfile" do
      # ISO 19103 MDG places some UMLProfile elements outside
      # <UMLProfiles> as root-level siblings. lutaml-model only
      # reads those inside <UMLProfiles>; the standalone diagram
      # profiles are a follow-up enhancement.
      expect(doc.stereotypes.size).to be >= 11
    end

    it "extracts CodeList applying to multiple element types" do
      cl = doc.find_stereotype("CodeList")
      expect(cl.applies_to).to include("Class", "DataType", "Enumeration")
    end
  end

  describe "format auto-detection" do
    it "parses XMI format without raising" do
      # XMI format returns a placeholder Document; full XMI parsing
      # via lutaml-model is a follow-up task.
      xmi = %(<XMI xmlns:UML="omg.org/UML1.3"><XMI.content></XMI.content></XMI>)
      doc = Ea::Mdg::Loader.from_xml(xmi).document
      expect(doc.technology_name).to eq("Unknown")
      expect(doc.classifiers).to eq([])
    end

    it "parses MDG.Technology format without raising" do
      mdg = <<~XML
        <?xml version="1.0"?>
        <MDG.Technology version="1.0">
          <Documentation id="x" name="Test" version="1.0"/>
          <UMLProfiles/>
        </MDG.Technology>
      XML
      doc = Ea::Mdg::Loader.from_xml(mdg).document
      expect(doc.technology_name).to eq("Test")
      expect(doc.classifiers).to eq([])
    end
  end
end
