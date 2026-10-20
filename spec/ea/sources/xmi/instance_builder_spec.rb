# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe "Sparx XMI instance specifications" do
  let(:document) { Ea::Sources::Xmi::Adapter.from_path(fixtures_path("basic.xmi")) }
  let(:instances) { document.instance_specifications }

  it "builds one instance specification per uml:InstanceSpecification" do
    expect(instances.map(&:name)).to eq(
      ["Object A", "Object B", "Object A", "Object B", "Object 01", "Object 02",
       "Object 03", "Object 01", "Object 02", "Object 05", "Object 03", "Object 04"]
    )
  end

  it "carries classifier, role, package and slots from the source" do
    instance = instances.find { |i| i.id == "EAID_61647CD7_2014_46d9_ADC0_A726E5E2A59B" }

    expect(
      [instance.role_name, instance.classifier_id, instance.classifier_name,
       instance.package_name, instance.qualified_name,
       instance.slots.map { |s| [s.name, s.op, s.value] }]
    ).to eq(
      ["roleOne", "EAID_4DEF666F_E8F2_4ace_B9AC_E15A5ACDCADD", "Class A", "Objects",
       "Objects::Object 01",
       [["attribute Two", "=", "Value Two"], ["attribute One", "=", "Value One"]]]
    )
  end

  it "keeps slot operators other than equals" do
    ops = instances.flat_map(&:slots).map(&:op)

    expect(ops.tally).to eq("=" => 21, "<=" => 1)
  end

  it "resolves instance specifications through the document index" do
    id = "EAID_9FE3DE09_E5E8_43bc_9CAE_7F227A3442A3"

    expect(document.index_by_id[id]).to be_a(Ea::Model::InstanceSpecification)
  end

  it "yields slot names from runstate when the typed slot has no defining feature" do
    instance = instances.find { |i| i.id == "EAID_9FE3DE09_E5E8_43bc_9CAE_7F227A3442A3" }

    expect(instance.slots.map { |s| [s.name, s.op, s.value] }).to eq([["Variable A", "=", "Value One"]])
  end
end
