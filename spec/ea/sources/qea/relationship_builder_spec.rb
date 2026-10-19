# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Sources::Qea::RelationshipBuilder do
  let(:source_id) { "11111111-2222-3333-4444-555555555555" }
  let(:target_id) { "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE" }
  let(:database) do
    Ea::Qea::Database.new(nil).tap do |db|
      db.add_collection(:objects, [
                          Ea::Qea::Models::EaObject.new(ea_object_id: 7, ea_guid: "{#{source_id}}"),
                          Ea::Qea::Models::EaObject.new(ea_object_id: 3, ea_guid: "{#{target_id}}")
                        ])
    end
  end
  let(:builder) { described_class.new(database) }

  it "imports dependency endpoints from the public basic QEA fixture" do
    parsed = Ea.parse(File.expand_path("../../../fixtures/basic.qea", __dir__))
    relationships = described_class.new(parsed).build_all
    dependency = relationships.find { |rel| rel.id == "3DC3F2A8-5EA3-4feb-B6D3-397DA58BBEA3" }

    expect(dependency).to be_a(Ea::Model::Dependency)
    expect(dependency.client_id).to eq("F5BFAAC7-BB6F-4f69-8C78-3775A0C86CDB")
    expect(dependency.supplier_id).to eq("45D98ADF-46E0-4bf6-B94F-8E504ABD1AB7")
  end

  {
    "Dependency" => [Ea::Model::Dependency, :client_id, :supplier_id],
    "Usage" => [Ea::Model::Dependency, :client_id, :supplier_id],
    "Abstraction" => [Ea::Model::Dependency, :client_id, :supplier_id],
    "Realization" => [Ea::Model::Realization, :realizing_id, :contract_id],
    "Association" => [Ea::Model::Association, :source_id, :target_id],
    "Generalization" => [Ea::Model::Generalization, :specific_id, :general_id]
  }.each do |type, (klass, source_attribute, target_attribute)|
    context "with a #{type} connector" do
      let(:row) do
        Ea::Qea::Models::EaConnector.new(
          connector_type: type, start_object_id: 7, end_object_id: 3,
          ea_guid: "{12345678-1234-1234-1234-123456789ABC}", name: "link",
          direction: "Destination -> Source"
        )
      end

      it "preserves stored start/end orientation regardless of direction" do
        relationship = builder.build_one(row)

        expect(relationship).to be_a(klass)
        expect(relationship.public_send(source_attribute)).to eq(source_id)
        expect(relationship.public_send(target_attribute)).to eq(target_id)
        expect(relationship.id).to eq("12345678-1234-1234-1234-123456789ABC")
        expect(relationship.name).to eq("link")
      end

      it "leaves an unresolved object reference empty without losing the other end" do
        row.end_object_id = 99
        relationship = builder.build_one(row)

        expect(relationship.public_send(source_attribute)).to eq(source_id)
        expect(relationship.public_send(target_attribute)).to be_nil
      end
    end
  end
end
