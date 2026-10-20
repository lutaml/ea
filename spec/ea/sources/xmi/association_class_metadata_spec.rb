# frozen_string_literal: true

require "spec_helper"
require "ostruct"

RSpec.describe Ea::Sources::Xmi::DiagramBuilder::AssociationClassMetadata do
  subject(:metadata) { described_class.new("spec/fixtures/association_class_tether_metadata.xmi") }

  let(:properties) { OpenStruct.new(ea_type: "Association", subtype: "Class") }
  let(:endpoint) do
    ->(id) { OpenStruct.new(idref: id, model: OpenStruct.new(type: "ProxyConnector")) }
  end
  let(:connector) do
    OpenStruct.new(idref: "EAID_ASSOC", properties: properties,
                   source: endpoint.call("EAID_PROXY_A"),
                   target: endpoint.call("EAID_PROXY_B"))
  end
  let(:point) { OpenStruct.new(x: 522, y: 644) }
  let(:waypoints) { [OpenStruct.new(position: point), OpenStruct.new(position: point)] }

  it "marks a placed association-class tether between coincident same-class proxies" do
    expect(metadata.for(connector, placed_subjects: ["EAID_CLASS"], waypoints: waypoints)).to eq("EAID_CLASS")
  end

  it "leaves generic association routes untouched" do
    properties.subtype = nil

    expect(metadata.for(connector, placed_subjects: ["EAID_CLASS"], waypoints: waypoints)).to be_nil
  end

  it "requires the attached class to be placed and the proxy route to be collapsed" do
    distinct = [OpenStruct.new(position: point), OpenStruct.new(position: OpenStruct.new(x: 523, y: 644))]

    expect(metadata.for(connector, placed_subjects: [], waypoints: waypoints)).to be_nil
    expect(metadata.for(connector, placed_subjects: ["EAID_CLASS"], waypoints: distinct)).to be_nil
  end
end

RSpec.describe Ea::Sources::Xmi::DiagramBuilder do
  it "attaches the discriminator while assembling a collapsed connector" do
    path = "spec/fixtures/association_class_tether_metadata.xmi"
    builder = described_class.new(OpenStruct.new, path)
    placed = OpenStruct.new(subject: "EAID_ASSOC", style: OpenStruct.new(duid: nil))
    class_placement = OpenStruct.new(subject: "EAID_CLASS", style: OpenStruct.new(duid: "CLASS_DUID"))
    diagram_connector = OpenStruct.new(style: {}, waypoints: [
                                         OpenStruct.new(position: OpenStruct.new(x: 522, y: 644)),
                                         OpenStruct.new(position: OpenStruct.new(x: 522, y: 644))
                                       ])
    properties = OpenStruct.new(ea_type: "Association", subtype: "Class")
    source = OpenStruct.new(idref: "EAID_PROXY_A", model: OpenStruct.new(type: "ProxyConnector"))
    target = OpenStruct.new(idref: "EAID_PROXY_B", model: OpenStruct.new(type: "ProxyConnector"))
    connector = OpenStruct.new(idref: "EAID_ASSOC", properties: properties,
                               source: source, target: target)
    allow(builder).to receive(:connector_index).and_return("EAID_ASSOC" => connector)
    allow(builder).to receive(:build_connector).and_return(diagram_connector)

    builder.send(:build_connectors, [placed], [class_placement], "DIAGRAM")

    expect(diagram_connector.style[:association_class_ref]).to eq("EAID_CLASS")
  end
end
