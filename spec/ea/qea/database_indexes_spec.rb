# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Qea::Database do
  describe "indexed query methods" do
    let(:constraint) do
      Ea::Qea::Models::EaObjectConstraint.new(
        constraint_id: 1,
        ea_object_id: 42,
        constraint: "self.size > 0",
        constraint_type: "Invariant",
      )
    end

    let(:tagged_value) do
      Ea::Qea::Models::EaTaggedValue.new(
        property_id: 1,
        element_id: "{GUID-1}",
        tag_value: "version|2.0",
      )
    end

    let(:object_property) do
      Ea::Qea::Models::EaObjectProperty.new(
        property_id: 1,
        ea_object_id: 42,
        property: "isCollection",
        value: "true",
      )
    end

    let(:xref) do
      Ea::Qea::Models::EaXref.new(
        client: "{GUID-1}",
        name: "Stereotypes",
        xref_type: "element property",
        description: "@STEREO;Name=Test;@ENDSTEREO;",
      )
    end

    let(:database) do
      build_test_database(
        object_constraints: [constraint],
        tagged_values: [tagged_value],
        object_properties: [object_property],
        xrefs: [xref],
      )
    end

    describe "#constraints_for_object" do
      it "returns constraints for given object id" do
        result = database.constraints_for_object(42)
        expect(result.size).to eq(1)
        expect(result.first.constraint).to eq("self.size > 0")
      end

      it "returns empty array for non-matching id" do
        expect(database.constraints_for_object(999)).to eq([])
      end
    end

    describe "#tagged_values_for_element" do
      it "returns tagged values for given element guid" do
        result = database.tagged_values_for_element("{GUID-1}")
        expect(result.size).to eq(1)
        expect(result.first.tag_name).to eq("version")
      end

      it "returns empty array for non-matching guid" do
        expect(database.tagged_values_for_element("{OTHER}")).to eq([])
      end
    end

    describe "#properties_for_object" do
      it "returns properties for given object id" do
        result = database.properties_for_object(42)
        expect(result.size).to eq(1)
        expect(result.first.property).to eq("isCollection")
      end

      it "returns empty array for non-matching id" do
        expect(database.properties_for_object(999)).to eq([])
      end
    end

    describe "#xrefs_for_client" do
      it "returns xrefs for given client guid" do
        result = database.xrefs_for_client("{GUID-1}")
        expect(result.size).to eq(1)
        expect(result.first.name).to eq("Stereotypes")
      end

      it "returns empty array for non-matching guid" do
        expect(database.xrefs_for_client("{OTHER}")).to eq([])
      end
    end

    describe "#close_connection" do
      it "does not raise when no connection exists" do
        expect { database.close_connection }.not_to raise_error
      end
    end
  end
end
