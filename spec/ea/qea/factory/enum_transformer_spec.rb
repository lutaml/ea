# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Qea::Factory::EnumTransformer do
  let(:database) { Ea::Qea::Database.new("test.qea") }
  let(:transformer) { described_class.new(database) }

  def enum_object
    Ea::Qea::Models::EaObject.new(
      ea_object_id: 92,
      object_type: "Enumeration",
      name: "brashIce",
      ea_guid: "{ENUM-GUID}",
    )
  end

  describe "#transform" do
    it "returns nil for nil input" do
      expect(transformer.transform(nil)).to be_nil
    end

    it "returns nil for non-enum objects" do
      ea_obj = Ea::Qea::Models::EaObject.new(
        ea_object_id: 1,
        object_type: "Class",
        name: "NotAnEnum",
      )

      expect(transformer.transform(ea_obj)).to be_nil
    end

    it "transforms an EA enumeration to a UML enum", :aggregate_failures do
      result = transformer.transform(enum_object)

      expect(result).to be_a(Lutaml::Uml::Enum)
      expect(result.name).to eq("brashIce")
      expect(result.xmi_id).to eq("EAID_ENUM_GUID")
    end

    it "maps literal defaults to initial values in Pos order", :aggregate_failures do
      literals = [
        Ea::Qea::Models::EaAttribute.new(
          ea_object_id: 92, name: "0/10 - 1/10", default: "1", pos: 0,
          ea_guid: "{LIT-1}",
        ),
        Ea::Qea::Models::EaAttribute.new(
          ea_object_id: 92, name: "1/10", default: "10", pos: 1,
          ea_guid: "{LIT-2}",
        ),
        Ea::Qea::Models::EaAttribute.new(
          ea_object_id: 92, name: "1/10 - 2/10", default: "12", pos: 2,
          ea_guid: "{LIT-3}",
        ),
      ]

      database.add_collection(:objects, [enum_object])
      database.add_collection(:attributes, literals)

      result = transformer.transform(enum_object)

      expect(result.values.map(&:name)).to eq(
        ["0/10 - 1/10", "1/10", "1/10 - 2/10"]
      )
      expect(result.values.map(&:initial)).to eq(%w[1 10 12])
    end

    it "leaves initial unset when the literal has no default" do
      literal = Ea::Qea::Models::EaAttribute.new(
        ea_object_id: 92, name: "noCode", pos: 0, ea_guid: "{LIT-1}",
      )

      database.add_collection(:objects, [enum_object])
      database.add_collection(:attributes, [literal])

      result = transformer.transform(enum_object)

      expect(result.values.first.initial).to be_nil
    end

    it "maps literal notes to definition" do
      literal = Ea::Qea::Models::EaAttribute.new(
        ea_object_id: 92, name: "0/10 - 1/10", default: "1", pos: 0,
        ea_guid: "{LIT-1}", notes: "Ice thickness up to 10 cm",
      )

      database.add_collection(:objects, [enum_object])
      database.add_collection(:attributes, [literal])

      result = transformer.transform(enum_object)

      expect(result.values.first.definition).to eq("Ice thickness up to 10 cm")
    end
  end
end
