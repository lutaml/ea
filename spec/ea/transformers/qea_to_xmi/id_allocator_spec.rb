# frozen_string_literal: true

require "spec_helper"
require "ea/transformers/qea_to_xmi"

RSpec.describe Ea::Transformers::QeaToXmi::IdAllocator do
  let(:allocator) { described_class.new }

  describe "#allocate" do
    it "returns an EAID_ prefixed identifier" do
      id = allocator.allocate(prefix: described_class::LITERAL_INTEGER)
      expect(id).to start_with("EAID_LI")
    end

    it "zero-pads the counter to 6 digits" do
      id = allocator.allocate(prefix: described_class::LITERAL_INTEGER)
      expect(id).to match(/EAID_LI000001\z/)
    end

    it "increments the counter across allocations" do
      first = allocator.allocate(prefix: described_class::LITERAL_INTEGER)
      second = allocator.allocate(prefix: described_class::LITERAL_INTEGER)
      third = allocator.allocate(prefix: described_class::LITERAL_INTEGER)

      expect(first).to end_with("LI000001")
      expect(second).to end_with("LI000002")
      expect(third).to end_with("LI000003")
    end

    it "accepts different prefixes" do
      li = allocator.allocate(prefix: described_class::LITERAL_INTEGER)
      oe = allocator.allocate(prefix: described_class::OPAQUE_EXPRESSION)
      rt = allocator.allocate(prefix: described_class::RETURN_PARAMETER)

      expect(li).to start_with("EAID_LI")
      expect(oe).to start_with("EAID_OE")
      expect(rt).to start_with("EAID_RT")
    end
  end

  describe "seed-based memoisation" do
    it "returns the same ID for the same seed" do
      id1 = allocator.allocate(prefix: described_class::LITERAL_INTEGER, seed: "attr-42-upper")
      id2 = allocator.allocate(prefix: described_class::LITERAL_INTEGER, seed: "attr-42-upper")

      expect(id1).to eq(id2)
    end

    it "returns different IDs for different seeds" do
      upper = allocator.allocate(prefix: described_class::LITERAL_INTEGER, seed: "attr-42-upper")
      lower = allocator.allocate(prefix: described_class::LITERAL_INTEGER, seed: "attr-42-lower")

      expect(upper).not_to eq(lower)
    end

    it "does not advance the counter when returning a memoised ID" do
      allocator.allocate(prefix: described_class::LITERAL_INTEGER, seed: "x")
      allocator.allocate(prefix: described_class::LITERAL_INTEGER, seed: "x") # memoised
      next_id = allocator.allocate(prefix: described_class::LITERAL_INTEGER, seed: "y")

      # Counter advanced exactly twice (once per distinct seed)
      expect(next_id).to end_with("LI000002")
    end

    it "still allocates when seed is nil" do
      id = allocator.allocate(prefix: described_class::LITERAL_INTEGER, seed: nil)
      expect(id).to start_with("EAID_LI")
    end

    it "treats nil seed as non-memoising (each call advances)" do
      id1 = allocator.allocate(prefix: described_class::LITERAL_INTEGER, seed: nil)
      id2 = allocator.allocate(prefix: described_class::LITERAL_INTEGER, seed: nil)

      expect(id1).to end_with("LI000001")
      expect(id2).to end_with("LI000002")
    end
  end

  describe "parent_guid incorporation (Sparx-conformant suffix)" do
    let(:guid) { "{6B8DB1D6-D01D-4acc-9C05-79018BCB3FB6}" }

    it "appends the parent GUID tail after the counter" do
      id = allocator.allocate(
        prefix: described_class::LITERAL_INTEGER,
        seed: "test",
        parent_guid: guid,
      )
      expect(id).to eq("EAID_LI000001__6B8DB1D6_D01D_4acc_9C05_79018BCB3FB6")
    end

    it "preserves the leading underscore from the opening brace" do
      # Real Sparx format is `EAID_LI<NN>__<guid_tail>` — the double
      # underscore is separator + brace-derived. Single underscore
      # would mean the GUID couldn't be traced back to its parent.
      id = allocator.allocate(
        prefix: described_class::LITERAL_INTEGER,
        seed: "test",
        parent_guid: guid,
      )
      expect(id).to include("LI000001__")
    end

    it "different parents with the same counter produce distinct IDs" do
      other_guid = "{AAAAAAAA-BBBB-cccc-dddd-EEEEEEEEEEEE}"
      id_a = allocator.allocate(prefix: described_class::LITERAL_INTEGER, seed: "a", parent_guid: guid)
      id_b = allocator.allocate(prefix: described_class::LITERAL_INTEGER, seed: "b", parent_guid: other_guid)

      expect(id_a).to include("6B8DB1D6")
      expect(id_b).to include("AAAAAAAA")
      expect(id_a).not_to eq(id_b)
    end

    it "omits the tail when parent_guid is nil" do
      id = allocator.allocate(
        prefix: described_class::LITERAL_INTEGER,
        seed: "test",
        parent_guid: nil,
      )
      expect(id).to eq("EAID_LI000001")
    end

    it "omits the tail when parent_guid is empty string" do
      id = allocator.allocate(
        prefix: described_class::LITERAL_INTEGER,
        seed: "test",
        parent_guid: "",
      )
      expect(id).to eq("EAID_LI000001")
    end
  end

  describe "well-known Sparx prefixes" do
    it "exposes LITERAL_INTEGER" do
      expect(described_class::LITERAL_INTEGER).to eq("LI")
    end

    it "exposes OPAQUE_EXPRESSION" do
      expect(described_class::OPAQUE_EXPRESSION).to eq("OE")
    end

    it "exposes SLOT" do
      expect(described_class::SLOT).to eq("SL")
    end

    it "exposes NAME_LABEL" do
      expect(described_class::NAME_LABEL).to eq("NL")
    end

    it "exposes DIAGRAM_BOUNDS" do
      expect(described_class::DIAGRAM_BOUNDS).to eq("DB")
    end

    it "exposes RETURN_PARAMETER" do
      expect(described_class::RETURN_PARAMETER).to eq("RT")
    end
  end
end
