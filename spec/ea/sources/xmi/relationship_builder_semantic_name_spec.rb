# frozen_string_literal: true

require "spec_helper"
require "ea"
require "xmi"

RSpec.describe Ea::Sources::Xmi::RelationshipBuilder, "semantic names" do
  let(:root) { Xmi::Sparx::Root.parse_xml(File.read(fixtures_path("basic.xmi"))) }
  let(:relationships) { described_class.new(root).build_all.to_h { |item| [item.id, item] } }

  it "keeps an unnamed association unnamed while preserving explicit association names" do
    expect(relationships.fetch("EAID_3B1A629A_3EED_45c3_85F2_D3F0D7607590").name).to be_nil
    expect(relationships.fetch("EAID_0273F609_8E33_4373_A292_D584DB6D5655").name).to eq("Link A")
    expect(relationships.fetch("EAID_97A0AE9F_F68E_45eb_978C_1C07724F2EFC").name).to eq("Link B")
  end
end
