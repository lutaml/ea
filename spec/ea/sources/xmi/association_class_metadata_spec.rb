# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Xmi::DiagramBuilder::AssociationClassMetadata do
  include XmiAssociationClassTetherHelpers

  let(:attached_class) { "EAID_F268A85D_5D50_44a5_9DB8_6F086487E858" }

  it "marks the saved association-class tether between coincident same-class proxies" do
    connector = tether_connector

    expect(connector.style[:association_class_ref]).to eq(attached_class)
    expect(points(connector)).to eq([[522, 644], [522, 644]])
  end

  it "leaves an association connector of another subtype unmarked" do
    connector = tether_connector(['subtype="Class"', 'subtype="Strong"'])

    expect(connector.style[:association_class_ref]).to be_nil
  end

  it "rejects proxies whose classifiers are both empty" do
    connector = tether_connector(*proxy_classifier(' classifier=""'))

    expect(connector.style[:association_class_ref]).to be_nil
  end

  it "rejects proxies without classifiers" do
    connector = tether_connector(*proxy_classifier(""))

    expect(connector.style[:association_class_ref]).to be_nil
  end

  it "requires a collapsed proxy route" do
    waypoint = 'WP000001_B679_4413_AC5C_018943F1B05F" x='
    connector = tether_connector(["#{waypoint}\"522\"", "#{waypoint}\"523\""])

    expect(connector.style[:association_class_ref]).to be_nil
  end
end

RSpec.describe "XMI association connectors without a model subtype" do
  it "imports basic.xmi, whose association properties carry no subtype accessor" do
    expect(Ea::Sources::Xmi::Adapter.from_path(fixtures_path("basic.xmi")).diagrams.size).to eq(22)
  end
end

RSpec.describe "XMI association-class tether rendering" do
  include XmiAssociationClassTetherHelpers

  it "renders the D36 collapsed proxy route as a tether to its association class" do
    connector = tether_connector

    expect([connector.source_anchor&.x, connector.source_anchor&.y]).to eq([522, 644])
    expect(points(connector)).to eq([[522, 644], [522, 644]])
    expect(rendered_tether_paths).to include("M 42 83 L 177 84")
  end

  it "preserves the collapsed UMLDI route for an ordinary association" do
    replacement = ['subtype="Class"', 'subtype="Strong"']

    expect(tether_connector(replacement).source_anchor).to be_nil
    expect(rendered_tether_paths(replacement)).to include("M 42 83 L 42 83")
  end
end
