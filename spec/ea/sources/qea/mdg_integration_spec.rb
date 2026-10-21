# frozen_string_literal: true

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
        <XMI.content><UML:Model name="MDG Test" xmi.id="MX_root"/></XMI.content>
      </XMI>
    XML
  end

  let(:registry) do
    registry = Ea::Mdg::Registry.new
    registry.register(
      Ea::Mdg::Document.new(
        technology_name: "MDG Test",
        classifiers: [
          Ea::Mdg::Document::ClassifierEntry.new(
            id: "EAID_PARENT", name: "Parent",
            properties: [Ea::Mdg::Document::PropertyEntry.new(
              name: "inheritedAttr", visibility: "public"
            )]
          ),
          Ea::Mdg::Document::ClassifierEntry.new(
            id: "EAID_BASE", name: "Base", properties: []
          )
        ],
        generalizations: [
          Ea::Mdg::Document::GeneralizationEntry.new(
            specific_id: "EAID_BASE", general_id: "EAID_PARENT"
          )
        ],
        packages: []
      )
    )
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

  it "loads an XMI MDG without raising" do
    expect { Ea::Mdg::Loader.from_xml(mdg_xml).document }.not_to raise_error
  end

  it "merges MDG-inherited attributes when a classifier's stereotype matches an MDG class" do
    # Drive the merge through ClassifierBuilder#properties_for directly
    # to avoid needing a full database stub for the surrounding build_one.
    stub_object = Struct.new(:ea_guid, :name, :object_type, :scope, :abstract,
                             :stereotype, :package_id, :parentid, :note,
                             :ea_object_id, keyword_init: true).new(
                               ea_guid: "{TEST_GUID}", name: "TestClass",
                               object_type: "Class", scope: "Public",
                               abstract: "0", stereotype: "Base",
                               package_id: nil, parentid: nil, note: "",
                               ea_object_id: 999
                             )
    own_attribute = Ea::Qea::Models::EaAttribute.new(
      ea_guid: "{OWN_GUID}", name: "ownBaseAttr", type: "String",
      lowerbound: "1", upperbound: "1", scope: "Public", pos: 0
    )
    stub_database = Class.new do
      define_method(:attributes_for_object) { |_object_id| [own_attribute] }
      define_method(:tagged_values_for_element) { |_element_id| [] }
    end.new
    builder = Ea::Sources::Qea::ClassifierBuilder.new(
      stub_database, mdg_registry: registry
    )
    base = registry.find_classifier_by_name("Base")
    expect(base).not_to be_nil
    expect(registry.inherited_properties_for(base.id).map(&:name)).to contain_exactly("inheritedAttr")

    properties = builder.properties_for(stub_object)
    expect(properties.map(&:name)).to contain_exactly("ownBaseAttr", "inheritedAttr")
  end
end
