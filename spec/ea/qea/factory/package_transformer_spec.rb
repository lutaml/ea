# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Qea::Factory::PackageTransformer do
  let(:database) { build_test_database }
  let(:transformer) { described_class.new(database) }

  describe "#transform" do
    it "returns nil for nil input" do
      result = transformer.transform(nil)
      expect(result).to be_nil
    end

    it "transforms EA package to UML package", :aggregate_failures do
      ea_pkg = Ea::Qea::Models::EaPackage.new(
        package_id: 1,
        name: "Domain",
        ea_guid: "{PKG-GUID}",
        notes: "Domain model package",
      )

      result = transformer.transform(ea_pkg)

      expect(result).to be_a(Lutaml::Uml::Package)
      expect(result.name).to eq("Domain")
      expect(result.xmi_id).to eq("EAPK_PKG_GUID")
      expect(result.definition).to eq("Domain model package")
      expect(result.packages).to eq([])
      expect(result.classes).to eq([])
    end

    it "skips empty notes" do
      ea_pkg = Ea::Qea::Models::EaPackage.new(
        package_id: 1,
        name: "Package",
        notes: "",
      )

      result = transformer.transform(ea_pkg)

      expect(result.definition).to be_nil
    end
  end

  describe "#transform_with_hierarchy" do
    it "loads child packages", :aggregate_failures do
      ea_pkg = Ea::Qea::Models::EaPackage.new(
        package_id: 1,
        name: "Root",
      )

      child_pkg = Ea::Qea::Models::EaPackage.new(
        package_id: 2,
        name: "Child",
        parent_id: 1,
        ea_guid: "{CHILD-GUID}",
      )

      database.add_collection(:packages, [ea_pkg, child_pkg])

      result = transformer.transform_with_hierarchy(ea_pkg)

      expect(result.packages.size).to eq(1)
      expect(result.packages.first.name).to eq("Child")
    end

    it "loads package objects as classes", :aggregate_failures do
      ea_pkg = Ea::Qea::Models::EaPackage.new(
        package_id: 1,
        name: "Models",
      )

      ea_obj = Ea::Qea::Models::EaObject.new(
        ea_object_id: 10,
        object_type: "Class",
        name: "Entity",
        package_id: 1,
      )

      database.add_collection(:packages, [ea_pkg])
      database.add_collection(:objects, [ea_obj])

      result = transformer.transform_with_hierarchy(ea_pkg)

      expect(result.classes.size).to eq(1)
      expect(result.classes.first.name).to eq("Entity")
    end

    it "loads package diagrams", :aggregate_failures do
      ea_pkg = Ea::Qea::Models::EaPackage.new(
        package_id: 1,
        name: "Views",
      )

      ea_diagram = Ea::Qea::Models::EaDiagram.new(
        diagram_id: 5,
        package_id: 1,
        name: "Class Diagram",
      )

      database.add_collection(:packages, [ea_pkg])
      database.add_collection(:diagrams, [ea_diagram])

      result = transformer.transform_with_hierarchy(ea_pkg)

      expect(result.diagrams.size).to eq(1)
      expect(result.diagrams.first.name).to eq("Class Diagram")
    end
  end
end
