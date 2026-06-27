# frozen_string_literal: true

require "spec_helper"
require "ea/transformers/qea_to_xmi"

RSpec.describe Ea::Transformers::QeaToXmi::GuidFormat do
  describe ".ea_guid_to_xmi_id" do
    it "converts a braced EA GUID to an EAID_ identifier" do
      input = "{AB12CD34-EF56-7890-ABCD-1234567890AB}"
      result = described_class.ea_guid_to_xmi_id(input)
      expect(result).to eq("EAID_AB12CD34_EF56_7890_ABCD_1234567890AB")
    end

    it "supports an EAPK_ prefix for model-root packages" do
      input = "{AB12CD34-EF56-7890-ABCD-1234567890AB}"
      result = described_class.ea_guid_to_xmi_id(input, prefix: "EAPK")
      expect(result).to eq("EAPK_AB12CD34_EF56_7890_ABCD_1234567890AB")
    end

    it "returns nil for nil input" do
      expect(described_class.ea_guid_to_xmi_id(nil)).to be_nil
    end

    it "returns nil for empty input" do
      expect(described_class.ea_guid_to_xmi_id("")).to be_nil
    end

    it "collapses consecutive underscores from brace-adjacent dashes" do
      result = described_class.ea_guid_to_xmi_id("{-A-B-}")
      expect(result).to eq("EAID_A_B")
    end

    it "strips leading and trailing underscores from braces" do
      result = described_class.ea_guid_to_xmi_id("{AB}")
      expect(result).to eq("EAID_AB")
    end
  end

  describe ".xmi_id_to_ea_guid" do
    it "converts an EAID_ identifier back to a braced GUID" do
      result = described_class.xmi_id_to_ea_guid("EAID_AB12_EF34")
      expect(result).to eq("{AB12-EF34}")
    end

    it "strips an EAPK_ prefix the same way" do
      result = described_class.xmi_id_to_ea_guid("EAPK_AB12_EF34")
      expect(result).to eq("{AB12-EF34}")
    end

    it "returns nil for nil input" do
      expect(described_class.xmi_id_to_ea_guid(nil)).to be_nil
    end
  end

  describe ".connector_end_xmi_id" do
    let(:connector_id) { "EAID_AB12CDEF_5678_90AB_CDEF_1234567890AB" }

    it "builds a source end id by trimming the first segment and prefixing src" do
      result = described_class.connector_end_xmi_id(connector_id, side: :source)
      expect(result).to eq("EAID_src12CDEF_5678_90AB_CDEF_1234567890AB")
    end

    it "builds a destination end id with dst prefix" do
      result = described_class.connector_end_xmi_id(connector_id, side: :destination)
      expect(result).to eq("EAID_dst12CDEF_5678_90AB_CDEF_1234567890AB")
    end

    it "matches Sparx's convention on a real connector id" do
      # EAID_1137B03A_... → EAID_dst37B03A_... (drop first 2 chars "11")
      result = described_class.connector_end_xmi_id(
        "EAID_1137B03A_C00A_443b_A3A8_D5CF6A7AFF13",
        side: :destination,
      )
      expect(result).to eq("EAID_dst37B03A_C00A_443b_A3A8_D5CF6A7AFF13")
    end

    it "handles short first segments without dropping extra chars" do
      result = described_class.connector_end_xmi_id("EAID_AB_CD", side: :source)
      expect(result).to eq("EAID_srcAB_CD")
    end
  end

  describe "round-trip" do
    it "xmi_id_to_ea_guid(ea_guid_to_xmi_id(x)) == x for normal forms" do
      ea_guid = "{AB-CD-EF-01-23}"
      xmi_id = described_class.ea_guid_to_xmi_id(ea_guid)
      roundtripped = described_class.xmi_id_to_ea_guid(xmi_id)
      expect(roundtripped).to eq(ea_guid)
    end
  end
end
