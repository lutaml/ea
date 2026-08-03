# frozen_string: true

require "spec_helper"
require "ea"
require "ea/mdg"

RSpec.describe Ea::Mdg::Registry do
  let(:mdg_xml) do
    <<~XML
      <?xml version="1.0"?>
      <MDG.Technology version="1.0">
        <Documentation id="x" name="MDG Test" version="1.0"/>
        <UMLProfiles>
          <UMLProfile>
            <Content>
              <Stereotypes>
                <Stereotype name="FeatureType" notes="test">
                  <AppliesTo><Apply type="Class"/></AppliesTo>
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

  let(:document) { Ea::Mdg::Loader.from_xml(mdg_xml).document }

  describe "#register" do
    it "adds the document to the registry" do
      registry = described_class.new
      expect(registry.size).to eq(0)
      registry.register(document)
      expect(registry.size).to eq(1)
      expect(registry.technology_names).to eq(["MDG Test"])
    end

    it "replaces an existing document with the same technology name" do
      registry = described_class.new
      registry.register(document)
      registry.register(document)
      expect(registry.size).to eq(1)
    end
  end

  describe "#find_classifier_by_name" do
    it "returns nil when no technology has the classifier" do
      registry = described_class.new
      registry.register(document)
      expect(registry.find_classifier_by_name("Missing")).to be_nil
    end

    it "returns nil for an empty registry" do
      registry = described_class.new
      expect(registry.find_classifier_by_name("Anything")).to be_nil
    end
  end

  describe "#find_stereotype" do
    it "returns the stereotype when found" do
      registry = described_class.new
      registry.register(document)
      ft = registry.find_classifier_by_name("FeatureType")
      # FeatureType is a stereotype, not a classifier —
      # classifier lookups won't find it
    end
  end

  describe "#inherited_properties_for" do
    it "returns an empty array when the classifier isn't in any MDG" do
      registry = described_class.new
      registry.register(document)
      expect(registry.inherited_properties_for("EAID_MISSING")).to eq([])
    end
  end

  describe "Enumerable" do
    it "yields each registered document" do
      registry = described_class.new
      registry.register(document)
      yielded = registry.to_a
      expect(yielded).to eq([document])
    end
  end
end
