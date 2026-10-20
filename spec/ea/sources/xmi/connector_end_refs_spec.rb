# frozen_string_literal: true

require "spec_helper"

RSpec.describe "XMI connector endpoint references from UMLDI edges" do
  include XmiConnectorEndHelpers

  let(:link_a) { XmiConnectorEndHelpers::LINK_A }
  let(:object_a) { XmiConnectorEndHelpers::OBJECT_A }
  let(:object_b) { XmiConnectorEndHelpers::OBJECT_B }

  it "joins a connector with stale SOID/EOID to its source and target placements" do
    expect(connector_end_models(basic_xmi_text, link_a)).to eq([object_a, object_b])
  end

  it "joins a package connector whose edge spells the GUID with another prefix and case" do
    expect(connector_end_models(basic_xmi_text, "EAID_EA8DF67D_FFE1_4ed1_9C8B_54DF19FE500B"))
      .to eq(%w[EAID_6F3B1CE6_F6D6_4990_8BE4_FC35840EF946 EAID_7A230AA5_32C5_47a1_B34F_A2CF1890AAAC])
  end

  it "resolves both ends of every basic connector and routes each one" do
    connectors = all_basic_connectors
    expect([connectors.size, connectors.count { |c| c.source_element_ref && c.target_element_ref },
            connectors.count { |c| c.waypoints.empty? }]).to eq([72, 72, 0])
  end

  it "keeps the end resolved by an existing DUID" do
    xmi = basic_with_source_duid_of(link_a, "F11A61F4")
    expect(connector_end_models(xmi, link_a)).to eq([object_b, object_b])
  end

  it "leaves an end unresolved when the edge's element is placed twice" do
    xmi = basic_with_duplicate_placement(object_a)
    expect(connector_end_models(xmi, link_a)).to eq([nil, object_b])
  end
end
