# frozen_string_literal: true

require "spec_helper"
require "ea/transformers/qea_to_xmi"

RSpec.describe Ea::Transformers::QeaToXmi::IdAllocator do
  subject(:allocator) { described_class.new }

  # Expected IDs are copied verbatim from examples/exports/basic/model.xml.
  # EA's scheme: the synthesized ID keeps the owner ID's total width —
  # "EAID_" + prefix + 6-digit counter + underscore padding + the owner
  # ID's last 27 characters. LI counts globally from 1 in allocation
  # order; SL/OE/RT count from 0 per owning element.
  describe "#allocate" do
    it "builds the LI ladder for association ends in EA's order" do
      dst = "EAID_dst2AA131_EEB1_4de7_98F5_670D6EE4A52B"
      src = "EAID_src2AA131_EEB1_4de7_98F5_670D6EE4A52B"
      ids = [
        allocator.allocate(prefix: "LI", owner_id: dst, seed: "dst-lower"),
        allocator.allocate(prefix: "LI", owner_id: dst, seed: "dst-upper"),
        allocator.allocate(prefix: "LI", owner_id: src, seed: "src-lower"),
        allocator.allocate(prefix: "LI", owner_id: src, seed: "src-upper")
      ]
      expect(ids).to eq(
        %w[
          EAID_LI000001__EEB1_4de7_98F5_670D6EE4A52B
          EAID_LI000002__EEB1_4de7_98F5_670D6EE4A52B
          EAID_LI000003__EEB1_4de7_98F5_670D6EE4A52B
          EAID_LI000004__EEB1_4de7_98F5_670D6EE4A52B
        ]
      )
    end

    it "keeps the global LI counter running across owners" do
      other_owner = "EAID_dst2AA131_EEB1_4de7_98F5_670D6EE4A52B"
      attr_id = "EAID_4D665E05_CA01_4c63_8311_0EC8F355E932"
      8.times { |i| allocator.allocate(prefix: "LI", owner_id: other_owner, seed: "warm-#{i}") }
      id = allocator.allocate(prefix: "LI", owner_id: attr_id, seed: "lower")
      expect(id).to eq("EAID_LI000009_CA01_4c63_8311_0EC8F355E932")
    end

    it "counts SL and OE from zero per owning instance" do
      instance = "EAID_7169D8F6_9F66_4e33_8E49_469BD346DAA1"
      expect(allocator.allocate(prefix: "SL", owner_id: instance, seed: "s0"))
        .to eq("EAID_SL000000_9F66_4e33_8E49_469BD346DAA1")
      expect(allocator.allocate(prefix: "OE", owner_id: instance, seed: "v0"))
        .to eq("EAID_OE000000_9F66_4e33_8E49_469BD346DAA1")
      expect(allocator.allocate(prefix: "SL", owner_id: instance, seed: "s1"))
        .to eq("EAID_SL000001_9F66_4e33_8E49_469BD346DAA1")
      expect(allocator.allocate(prefix: "OE", owner_id: instance, seed: "v1"))
        .to eq("EAID_OE000001_9F66_4e33_8E49_469BD346DAA1")
    end

    it "restarts RT at zero for every operation" do
      op1 = "EAID_11111111_3EE1_4598_9615_F2068D192111"
      op2 = "EAID_22222222_B122_4b05_863F_1918B52A0C0C"
      expect(allocator.allocate(prefix: "RT", owner_id: op1, seed: "r1"))
        .to eq("EAID_RT000000_3EE1_4598_9615_F2068D192111")
      expect(allocator.allocate(prefix: "RT", owner_id: op2, seed: "r2"))
        .to eq("EAID_RT000000_B122_4b05_863F_1918B52A0C0C")
    end

    it "memoizes by owner, prefix and seed" do
      owner = "EAID_4D665E05_CA01_4c63_8311_0EC8F355E932"
      first = allocator.allocate(prefix: "LI", owner_id: owner, seed: "lower")
      expect(allocator.allocate(prefix: "LI", owner_id: owner, seed: "lower")).to eq(first)
    end

    it "does not advance the LI counter when returning a memoized ID" do
      owner = "EAID_4D665E05_CA01_4c63_8311_0EC8F355E932"
      allocator.allocate(prefix: "LI", owner_id: owner, seed: "x")
      allocator.allocate(prefix: "LI", owner_id: owner, seed: "x")
      second = allocator.allocate(prefix: "LI", owner_id: owner, seed: "y")
      expect(second).to eq("EAID_LI000002_CA01_4c63_8311_0EC8F355E932")
    end

    it "emits a tailless id when the owner has no usable id" do
      expect(allocator.allocate(prefix: "LI", owner_id: nil, seed: "s"))
        .to eq("EAID_LI000001")
    end

    it "allocates independently for the same seed under different owners" do
      op1 = "EAID_11111111_3EE1_4598_9615_F2068D192111"
      op2 = "EAID_22222222_B122_4b05_863F_1918B52A0C0C"
      first = allocator.allocate(prefix: "RT", owner_id: op1, seed: "return")
      second = allocator.allocate(prefix: "RT", owner_id: op2, seed: "return")
      expect(first).not_to eq(second)
    end
  end
end
