# frozen_string_literal: true

require "spec_helper"

RSpec.describe "XMI connectors without saved placement endpoints" do
  include XmiConnectorEndHelpers
  include XmiConnectorFallbackHelpers

  let(:link) { XmiConnectorEndHelpers::LINK_A }
  let(:expected_ends) { [XmiConnectorEndHelpers::OBJECT_A, XmiConnectorEndHelpers::OBJECT_B] }

  it "retains source-known connectors and their native route" do
    state = fallback_connector_state(without_saved_connector_ends(basic_xmi_text, link), link)
    expect(state).to eq([expected_ends, [[190, 125], [315, 125]]])
  end

  it "keeps recovered endpoint roles authoritative without manufacturing label boxes" do
    diagram = fallback_connector_diagram(without_saved_connector_ends(basic_xmi_text, link), link)
    connector = diagram.connectors.find { |item| item.relationship_ref == link }

    expect(connector.style[:explicit_end_roles]).to be(true)
    expect(connector.label_boxes).to be_empty
  end

  it "routes between unique extension endpoints without a UMLDI edge" do
    state = fallback_connector_state(without_saved_connector_ends(basic_xmi_text, link, remove_edge: true), link)
    expect(state&.first).to eq(expected_ends)
    expect(state&.last&.size).to be >= 2
  end

  it "keeps duplicate model placements ambiguous" do
    xml = basic_with_duplicate_placement(expected_ends.first)
    state = fallback_connector_state(without_saved_connector_ends(xml, link, remove_edge: true), link)
    expect(state).to eq([[nil, expected_ends.last], []])
  end
end
