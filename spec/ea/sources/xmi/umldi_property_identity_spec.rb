# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe Ea::Sources::Xmi::DiagramBuilder::UmldiEdges, "property identity" do
  include UmldiPropertyIdentityHelpers

  it "identifies the target role owned by the declared association member" do
    with_property_label_identity do |edges|
      expect(edges.property_role_keys_for("diagram", "association")).to eq([:target_role])
      expect(edges.label_bounds_for("diagram", "association"))
        .to eq(target_role: { x: 767, y: 288, width: 86, height: 13 })
    end
  end

  it "rejects a property declared for a different association" do
    change = ->(xml) { xml.at_xpath("//*[@association]")["association"] = "other" }
    with_property_label_identity(change) do |edges|
      expect(edges.property_role_keys_for("diagram", "association")).to eq([])
    end
  end

  it "rejects a declaration without an association member" do
    change = ->(xml) { xml.at_xpath("//*[local-name()='memberEnd']").remove }
    with_property_label_identity(change) do |edges|
      expect(edges.property_role_keys_for("diagram", "association")).to eq([])
    end
  end
end

RSpec.describe Ea::Sources::Xmi::DiagramBuilder::UmldiEdges, "ambiguous label identity" do
  include UmldiPropertyIdentityHelpers

  it "keeps ambiguous duplicate edges ineligible" do
    change = lambda do |xml|
      edge = xml.at_xpath("//*[@modelElement='association']")
      edge.add_next_sibling(edge.dup)
    end
    with_property_label_identity(change) do |edges|
      expect(edges.property_role_keys_for("diagram", "association")).to eq([])
      expect(edges.label_bounds_for("diagram", "association")).to be_nil
    end
  end

  it "does not promote multiplicity boxes to authoritative role labels" do
    change = lambda do |xml|
      label = xml.at_xpath("//*[@modelElement='property']")
      label["xmi:type"] = "umldi:UMLMultiplicityLabel"
      label["xmi:id"] = "EAID_TML_label"
    end
    with_property_label_identity(change) do |edges|
      expect(edges.property_role_keys_for("diagram", "association")).to eq([])
    end
  end
end

RSpec.describe Ea::Sources::Xmi::DiagramBuilder::UmldiEdges, "source role preservation" do
  include UmldiPropertyIdentityHelpers

  it "does not promote a source role over stored extension geometry" do
    change = ->(xml) { xml.at_xpath("//*[@modelElement='property']")["xmi:id"] = "EAID_SEL_label" }
    with_property_label_identity(change) do |edges|
      expect(edges.property_role_keys_for("diagram", "association")).to eq([])
      expect(edges.label_bounds_for("diagram", "association"))
        .to eq(source_role: { x: 767, y: 288, width: 86, height: 13 })
    end
  end
end
