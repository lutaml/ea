# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.shared_examples "actual Property identity" do |name, data|
  it "joins the actual Property, memberEnd, diagram and endpoints" do
    property = xml.at_xpath("//*[@xmi:id='#{data[:property]}']")
    association = xml.at_xpath("//*[@xmi:id='#{data[:association]}']")
    expect(property["association"]).to eq(data[:association])
    expect(property["name"]).to eq(name)
    expect(property.at_xpath("./type")["xmi:idref"]).to eq(data[:source])
    expect(association.xpath("./memberEnd").map { |member| member["xmi:idref"] })
      .to contain_exactly(data[:property], data[:property].sub("EAID_src", "EAID_dst"))
    expect(diagram.id).to eq(data[:diagram])
    expect(association_model.source_role_name).to eq(name)
    expect(association_model.target_role_name).to be_nil
    expect(connector.source_stereotype).to eq("property")
    expect(association_model.source_id).to eq(data[:source])
    expect(association_model.target_id).to eq(data[:target])
  end
end

RSpec.shared_examples "authored Property geometry" do |_name, data|
  it "preserves authored role bounds, route, ports and stored label boxes" do
    expect(connector.umldi_label_bounds).to eq(source_role: data[:bounds])
    expect(property_source_route(connector)).to eq(data[:route])
    expect(property_source_ports(connector)).to eq(data[:ports])
    expect([connector.source_edge, connector.target_edge]).to eq(data[:edges])
    expect(property_source_bounds(diagram, connector.source_element_ref)).to eq(data[:source_bounds])
    expect(property_source_bounds(diagram, connector.target_element_ref)).to eq(data[:target_bounds])
    expect(property_source_box(connector, :llt)).to eq(data[:llt])
    expect(property_source_box(connector, :llb)).to eq(data[:llb])
    expect(association_model.source_multiplicity_raw).to eq(data[:multiplicity])
  end
end

RSpec.shared_examples "Property identity exclusions" do |_name, data|
  Issue135PropertySourceAcceptanceHelpers::IDENTITY_CHANGES.each do |guard, change|
    it "rejects role-bound ownership for #{guard} without changing extension geometry" do
      change.call(xml, data)
      expect(connector.umldi_label_bounds).to eq({})
      # Duplicate UMLDI edges also invalidate the authored route lookup.
      expect(property_source_route(connector)).to eq(data[:route]) unless guard == "duplicate edge"
      expect(property_source_ports(connector)).to eq(data[:ports])
      expect(property_source_box(connector, :llt)).to eq(data[:llt])
      expect(property_source_box(connector, :llb)).to eq(data[:llb])
      expect(association_model.source_multiplicity_raw).to eq(data[:multiplicity])
    end
  end
end

Issue135PropertySourceAcceptanceHelpers::CASES.each do |name, data|
  RSpec.describe "Issue 135 actual #{name} source acceptance" do
    include Issue135PropertySourceAcceptanceHelpers

    let(:xml) { property_source_xml(data) }
    let(:document) { property_source_document(xml) }
    let(:diagram) { document.diagrams.first }
    let(:association_model) { document.relationships.find { |item| item.id == data[:association] } }
    let(:connector) { diagram.connectors.find { |item| item.relationship_ref == data[:association] } }

    include_examples "actual Property identity", name, data
    include_examples "authored Property geometry", name, data
    include_examples "Property identity exclusions", name, data
  end
end
