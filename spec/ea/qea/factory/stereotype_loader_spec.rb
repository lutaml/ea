# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Qea::Factory::StereotypeLoader do
  let(:ea_guid) { "{ABC12345-DEFG-6789-IJKL-012345678901}" }
  let(:xref) do
    Ea::Qea::Models::EaXref.new(
      client: ea_guid,
      name: "Stereotypes",
      xref_type: "element property",
      description: "@STEREO;Name=ApplicationSchema;FQName=GML::ApplicationSchema;@ENDSTEREO;",
    )
  end

  describe "#load_from_xref" do
    it "returns stereotype name from xref" do
      database = build_test_database(xrefs: [xref])
      loader = described_class.new(database)

      expect(loader.load_from_xref(ea_guid)).to eq("ApplicationSchema")
    end

    it "returns nil when no matching xref found" do
      database = build_test_database(xrefs: [])
      loader = described_class.new(database)

      expect(loader.load_from_xref(ea_guid)).to be_nil
    end

    it "returns nil when xref has no description" do
      empty_xref = Ea::Qea::Models::EaXref.new(
        client: ea_guid,
        name: "Stereotypes",
        xref_type: "element property",
        description: nil,
      )
      database = build_test_database(xrefs: [empty_xref])
      loader = described_class.new(database)

      expect(loader.load_from_xref(ea_guid)).to be_nil
    end

    it "returns nil when xref has empty description" do
      empty_xref = Ea::Qea::Models::EaXref.new(
        client: ea_guid,
        name: "Stereotypes",
        xref_type: "element property",
        description: "",
      )
      database = build_test_database(xrefs: [empty_xref])
      loader = described_class.new(database)

      expect(loader.load_from_xref(ea_guid)).to be_nil
    end

    it "returns nil for nil guid" do
      database = build_test_database
      loader = described_class.new(database)

      expect(loader.load_from_xref(nil)).to be_nil
    end

    it "ignores xrefs with different name" do
      wrong_xref = Ea::Qea::Models::EaXref.new(
        client: ea_guid,
        name: "OtherProperty",
        xref_type: "element property",
        description: "@STEREO;Name=Test;@ENDSTEREO;",
      )
      database = build_test_database(xrefs: [wrong_xref])
      loader = described_class.new(database)

      expect(loader.load_from_xref(ea_guid)).to be_nil
    end
  end
end
