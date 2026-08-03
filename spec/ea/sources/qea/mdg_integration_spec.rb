# frozen_string: true

require "spec_helper"
require "ea"
require "ea/mdg"

RSpec.describe "QEA + MDG integration", :qea_regression do
  QEA_PATH = File.expand_path("../../../../examples/qea/basic.qea", __dir__)

  let(:mdg_xml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <XMI xmi.version="1.1" xmlns:UML="omg.org/UML1.3">
        <XMI.content>
          <UML:Model name="EA Model" xmi.id="MX_root">
            <UML:Namespace.ownedElement>
              <UML:Package name="MDG Test" xmi.id="EAPK_test">
                <UML:Namespace.ownedElement>
                  <UML:Class name="Parent" xmi.id="EAID_PARENT">
                    <UML:Classifier.feature>
                      <UML:Attribute name="inheritedAttr" visibility="public"/>
                    </UML:Classifier.feature>
                  </UML:Class>
                  <UML:Class name="Base" xmi.id="EAID_BASE">
                    <UML:Classifier.feature>
                      <UML:Attribute name="ownBaseAttr" visibility="public"/>
                    </UML:Classifier.feature>
                  </UML:Class>
                  <UML:Generalization subtype="EAID_BASE" supertype="EAID_PARENT" xmi.id="EAID_GEN1"/>
                </UML:Namespace.ownedElement>
              </UML:Package>
            </UML:Namespace.ownedElement>
          </UML:Model>
        </XMI.content>
      </XMI>
    XML
  end

  let(:registry) do
    registry = Ea::Mdg::Registry.new
    registry.register(Ea::Mdg::Loader.from_xml(mdg_xml).document)
    registry
  end

  before(:all) { skip "basic.qea not available" unless File.exist?(QEA_PATH) }

  it "loads QEA with no mdg_registry (backward compatible)" do
    doc = Ea::Sources::Qea::Adapter.from_path(QEA_PATH)
    expect(doc.classifiers).not_to be_empty
  end

  it "loads QEA with an mdg_registry without raising" do
    doc = Ea::Sources::Qea::Adapter.from_path(QEA_PATH, mdg_registry: registry)
    expect(doc.classifiers).not_to be_empty
  end

  it "merges MDG-inherited attributes when a classifier's stereotype matches an MDG class" do
    # Drive the merge through ClassifierBuilder#properties_for directly
    # to avoid needing a full database stub for the surrounding build_one.
    stub_object = Struct.new(:ea_guid, :name, :object_type, :scope, :abstract,
                             :stereotype, :package_id, :parentid, :note,
                             :ea_object_id, keyword_init: true).new(
      ea_guid: "{TEST_GUID}", name: "TestClass", object_type: "Class",
      scope: "Public", abstract: "0", stereotype: "Base",
      package_id: nil, parentid: nil, note: "", ea_object_id: 999
    )
    stub_database = Class.new do
      def attributes_for_object(*) = []
    end.new
    builder = Ea::Sources::Qea::ClassifierBuilder.new(stub_database,
                                                       mdg_registry: registry)
    properties = builder.properties_for(stub_object)
    expect(properties.map(&:name)).to include("inheritedAttr")
  end
end
