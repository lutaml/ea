# frozen_string_literal: true

require "spec_helper"
require "ea"
require "xmi"

RSpec.describe Ea::Sources::Xmi::RelationshipBuilder, "association ends" do
  let(:root) { Xmi::Sparx::Root.parse_xml(File.read(fixtures_path("basic.xmi"))) }
  let(:by_id) { described_class.new(root).build_all.to_h { |item| [item.id, item] } }

  context "with the saved connector ends" do
    it "takes classifier ids, roles and raw multiplicities from the connector ends" do
      rel = by_id.fetch("EAID_12C9D05B_3FBE_4c66_A0C1_1B210B499EB3")

      expect(rel).to have_attributes(
        source_id: "EAID_A4BDBE65_C5CF_4ba8_8CEF_C2C6796BDEC8",
        target_id: "EAID_B68D063E_45AD_450b_9656_68B35E3C8DAF",
        source_role_name: "role a", target_role_name: "role b",
        source_multiplicity_raw: "0..*", target_multiplicity_raw: "0..*",
        source_multiplicity_lower: 0, source_multiplicity_upper: -1,
        target_multiplicity_lower: 0, target_multiplicity_upper: -1
      )
    end

    it "splits a bounded multiplicity into lower and upper" do
      rel = by_id.fetch("EAID_A46BF7AB_4B06_4018_B2F5_705C440837BA")

      expect(rel).to have_attributes(
        source_role_name: "roleTwo", target_role_name: "roleOne",
        source_multiplicity_raw: "0..2", target_multiplicity_raw: "1",
        source_multiplicity_lower: 0, source_multiplicity_upper: 2,
        target_multiplicity_lower: 1, target_multiplicity_upper: 1
      )
    end

    it "leaves unspecified multiplicities unset" do
      rel = by_id.fetch("EAID_1137B03A_C00A_443b_A3A8_D5CF6A7AFF13")

      expect(rel).to have_attributes(
        source_multiplicity_raw: nil, target_multiplicity_raw: nil,
        source_multiplicity_lower: nil, target_multiplicity_upper: nil
      )
    end

    it "gives an Aggregation connector a shared source end" do
      rel = by_id.fetch("EAID_B3CF64D9_3CAA_41e2_862C_8C4A9BA09AC2")

      expect(rel).to have_attributes(source_aggregation: "shared", target_aggregation: "shared",
                                     source_multiplicity_raw: "0..3", source_role_name: "roleThree")
    end
  end

  context "without an extension connector" do
    before { root.extension = nil }

    it "keeps the owned-end ids, roles and defaulted multiplicities" do
      rel = by_id.fetch("EAID_12C9D05B_3FBE_4c66_A0C1_1B210B499EB3")

      expect(rel).to have_attributes(
        source_id: "EAID_dstC9D05B_3FBE_4c66_A0C1_1B210B499EB3",
        target_id: "EAID_srcC9D05B_3FBE_4c66_A0C1_1B210B499EB3",
        source_role_name: "role b", target_role_name: "role a",
        source_multiplicity_raw: nil, source_multiplicity_upper: -1
      )
    end
  end
end

RSpec.describe Ea::Sources::Xmi::RelationshipBuilder, "connector stereotypes" do
  let(:by_id) do
    Ea::Sources::Xmi::Adapter.from_path(fixtures_path("basic.xmi"))
                             .relationships.to_h { |item| [item.id, item] }
  end

  it "builds the package import connector as an «import» association" do
    rel = by_id.fetch("EAID_12D9B35C_220D_4d31_A3DB_81BCEE4A226B")

    expect(rel).to be_a(Ea::Model::Association).and have_attributes(
      stereotype: "import", name: nil,
      source_id: "EAID_B384E7CC_6668_4460_B582_EB0F9E31AABA",
      target_id: "EAID_4FB8D58C_0C14_4380_81E8_0D743A9919E5",
      source_navigable: false, target_navigable: true
    )
  end

  it "builds the second package import" do
    expect(by_id.fetch("EAID_70958216_0289_487e_B32F_96CA8B4F1D14").stereotype).to eq("import")
  end

  it "leaves unstereotyped associations without a stereotype" do
    expect(by_id.fetch("EAID_12C9D05B_3FBE_4c66_A0C1_1B210B499EB3")).to have_attributes(stereotype: nil, name: "Name A")
  end
end
