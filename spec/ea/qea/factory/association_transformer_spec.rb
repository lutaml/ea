# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Qea::Factory::AssociationTransformer do
  let(:source_obj) do
    Ea::Qea::Models::EaObject.new(
      ea_object_id: 10, name: "Person", ea_guid: "{PERSON-GUID}",
    )
  end
  let(:dest_obj) do
    Ea::Qea::Models::EaObject.new(
      ea_object_id: 20, name: "Building", ea_guid: "{BUILDING-GUID}",
    )
  end
  let(:database) { build_test_database(objects: [source_obj, dest_obj]) }
  let(:transformer) { described_class.new(database) }

  describe "#transform" do
    let(:ea_conn) do
      Ea::Qea::Models::EaConnector.new(
        connector_id: 1,
        connector_type: "Association",
        name: "owns",
        ea_guid: "{ASSOC-GUID}",
        start_object_id: 10,
        end_object_id: 20,
        sourcerole: "owner",
        destrole: "property",
        sourcecard: "1",
        destcard: "0..*",
        notes: "Ownership relationship",
      )
    end

    it "returns nil for nil input" do
      result = transformer.transform(nil)
      expect(result).to be_nil
    end

    it "returns nil for non-association connectors" do
      ea_conn = Ea::Qea::Models::EaConnector.new(
        connector_type: "Generalization",
      )

      result = transformer.transform(ea_conn)

      expect(result).to be_nil
    end

    it "transforms EA association to UML association", :aggregate_failures do
      result = transformer.transform(ea_conn)

      expect(result).to be_a(Lutaml::Uml::Association)
      expect(result.name).to eq("owns")
      expect(result.xmi_id).to eq("EAID_ASSOC_GUID")
      expect(result.owner_end).to eq("Person")
      expect(result.member_end).to eq("Building")
      expect(result.owner_end_attribute_name).to eq("owner")
      expect(result.member_end_attribute_name).to eq("property")
      expect(result.definition).to eq("Ownership relationship")
    end

    it "builds cardinality for source end", :aggregate_failures do
      ea_conn = Ea::Qea::Models::EaConnector.new(
        connector_type: "Association",
        start_object_id: 10,
        end_object_id: 20,
        sourcecard: "1..*",
      )

      result = transformer.transform(ea_conn)

      expect(result.owner_end_cardinality).to be_a(Lutaml::Uml::Cardinality)
      expect(result.owner_end_cardinality.min).to eq("1")
      expect(result.owner_end_cardinality.max).to eq("*")
    end

    it "maps stereotype" do
      ea_conn = Ea::Qea::Models::EaConnector.new(
        connector_type: "Association",
        start_object_id: 10,
        end_object_id: 20,
        stereotype: "create",
      )

      result = transformer.transform(ea_conn)

      expect(result.stereotype).to eq(["create"])
    end
  end
end
