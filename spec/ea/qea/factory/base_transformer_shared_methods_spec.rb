# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Qea::Factory::BaseTransformer do
  describe "shared methods" do
    let(:database) { build_test_database }

    let(:transformer) do
      described_class.new(database)
    end

    describe "#load_tagged_values" do
      it "returns empty array for nil guid" do
        expect(transformer.load_tagged_values(nil)).to eq([])
      end

      it "returns empty array when no tagged values match" do
        tag = Ea::Qea::Models::EaTaggedValue.new(
          property_id: 1,
          element_id: "{OTHER-GUID}",
          tag_name: "test",
          value: "val",
        )
        db = build_test_database(tagged_values: [tag])
        t = described_class.new(db)

        result = t.load_tagged_values("{TARGET-GUID}")
        expect(result).to eq([])
      end

      it "transforms matching tagged values" do
        tag = Ea::Qea::Models::EaTaggedValue.new(
          property_id: 1,
          element_id: "{TARGET-GUID}",
          tag_value: "version|1.0",
        )
        db = build_test_database(tagged_values: [tag])
        t = described_class.new(db)

        result = t.load_tagged_values("{TARGET-GUID}")
        expect(result.size).to eq(1)
        expect(result.first.name).to eq("version")
      end
    end

    describe "#load_attributes" do
      it "returns empty array for nil object_id" do
        expect(transformer.load_attributes(nil)).to eq([])
      end

      it "returns empty array when no attributes match" do
        expect(transformer.load_attributes(999)).to eq([])
      end
    end

    describe "#load_operations" do
      it "returns empty array for nil object_id" do
        expect(transformer.load_operations(nil)).to eq([])
      end

      it "returns empty array when no operations match" do
        expect(transformer.load_operations(999)).to eq([])
      end
    end

    describe "#load_constraints" do
      it "returns empty array for nil object_id" do
        expect(transformer.load_constraints(nil)).to eq([])
      end

      it "returns empty array when no constraints match" do
        expect(transformer.load_constraints(999)).to eq([])
      end
    end

    describe "#load_object_properties" do
      it "returns empty array for nil object_id" do
        expect(transformer.load_object_properties(nil)).to eq([])
      end

      it "returns empty array when no properties match" do
        expect(transformer.load_object_properties(999)).to eq([])
      end
    end
  end
end
