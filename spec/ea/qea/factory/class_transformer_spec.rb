# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Qea::Factory::ClassTransformer do
  let(:database) { build_test_database }
  let(:transformer) { described_class.new(database) }

  describe "#transform" do
    it "returns nil for nil input" do
      result = transformer.transform(nil)
      expect(result).to be_nil
    end

    it "returns nil for non-class objects" do
      ea_obj = Ea::Qea::Models::EaObject.new(
        object_type: "Package",
      )

      result = transformer.transform(ea_obj)

      expect(result).to be_nil
    end

    it "transforms EA class object to UML class", :aggregate_failures do
      ea_obj = Ea::Qea::Models::EaObject.new(
        ea_object_id: 1,
        object_type: "Class",
        name: "Building",
        ea_guid: "{CLASS-GUID}",
        abstract: "0",
        visibility: "Public",
        note: "Represents a building",
      )

      database.add_collection(:objects, [ea_obj])

      result = transformer.transform(ea_obj)

      expect(result).to be_a(Lutaml::Uml::UmlClass)
      expect(result.name).to eq("Building")
      expect(result.xmi_id).to eq("EAID_CLASS_GUID")
      expect(result.is_abstract).to be false
      expect(result.visibility).to eq("public")
      expect(result.definition).to eq("Represents a building")
    end

    it "marks abstract classes" do
      ea_obj = Ea::Qea::Models::EaObject.new(
        ea_object_id: 1,
        object_type: "Class",
        name: "Shape",
        abstract: "1",
      )

      database.add_collection(:objects, [ea_obj])

      result = transformer.transform(ea_obj)

      expect(result.is_abstract).to be true
    end

    it "adds interface stereotype for interfaces" do
      ea_obj = Ea::Qea::Models::EaObject.new(
        ea_object_id: 1,
        object_type: "Interface",
        name: "IDrawable",
      )

      database.add_collection(:objects, [ea_obj])

      result = transformer.transform(ea_obj)

      expect(result.stereotype).to include("interface")
    end

    it "loads and transforms attributes", :aggregate_failures do
      ea_obj = Ea::Qea::Models::EaObject.new(
        ea_object_id: 1,
        object_type: "Class",
        name: "Person",
      )

      ea_attr = Ea::Qea::Models::EaAttribute.new(
        id: 1,
        ea_object_id: 1,
        name: "firstName",
        type: "String",
        scope: "Private",
        pos: 0,
      )

      database.add_collection(:objects, [ea_obj])
      database.add_collection(:attributes, [ea_attr])

      result = transformer.transform(ea_obj)

      expect(result.attributes.size).to eq(1)
      expect(result.attributes.first.name).to eq("firstName")
    end

    it "loads and transforms operations", :aggregate_failures do
      ea_obj = Ea::Qea::Models::EaObject.new(
        ea_object_id: 1,
        object_type: "Class",
        name: "Calculator",
      )

      ea_op = Ea::Qea::Models::EaOperation.new(
        operationid: 1,
        ea_object_id: 1,
        name: "add",
        type: "Integer",
        scope: "Public",
        pos: 0,
      )

      database.add_collection(:objects, [ea_obj])
      database.add_collection(:operations, [ea_op])

      result = transformer.transform(ea_obj)

      expect(result.operations.size).to eq(1)
      expect(result.operations.first.name).to eq("add")
    end

    it "preserves stereotype" do
      ea_obj = Ea::Qea::Models::EaObject.new(
        ea_object_id: 1,
        object_type: "Class",
        name: "Entity",
        stereotype: "entity",
      )

      database.add_collection(:objects, [ea_obj])

      result = transformer.transform(ea_obj)

      expect(result.stereotype).to eq(["entity"])
    end
  end
end
