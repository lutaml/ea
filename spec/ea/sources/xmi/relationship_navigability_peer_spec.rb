# frozen_string_literal: true

require "spec_helper"
require "ea"
require "xmi"

RSpec.describe Ea::Sources::Xmi::RelationshipBuilder, "endpoint navigability" do
  let(:root) { Xmi::Sparx::Root.parse_xml(File.read(fixtures_path("basic.xmi"))) }
  let(:connector) { root.extension.connectors.connector.first }
  let(:relationship_id) { Ea::Sources::Xmi::IdNormalizer.from_xmi_id(connector.idref) }
  let(:relationship) { described_class.new(root).build_all.find { |item| item.id == relationship_id } }

  [[false, true], [true, false], [false, false], [true, true], [nil, nil]].each do |source, target|
    it "imports endpoint flags #{source.inspect}/#{target.inspect} for the matching connector" do
      connector.source.modifiers.is_navigable = source
      connector.target.modifiers.is_navigable = target

      expect(relationship.source_navigable).to eq(source.nil? || source)
      expect(relationship.target_navigable).to eq(target.nil? || target)
    end
  end

  it "imports the real fixture's explicitly non-navigable endpoints" do
    expect(relationship.source_navigable).to be(false)
    expect(relationship.target_navigable).to be(false)
  end
end

RSpec.describe Ea::Sources::Xmi::RelationshipBuilder, "unspecified endpoint navigability" do
  let(:root) { Xmi::Sparx::Root.parse_xml(File.read(fixtures_path("basic.xmi"))) }
  let(:connector) { root.extension.connectors.connector.first }
  let(:relationship_id) { Ea::Sources::Xmi::IdNormalizer.from_xmi_id(connector.idref) }
  let(:relationship) { described_class.new(root).build_all.find { |item| item.id == relationship_id } }

  it "defaults missing endpoints to navigable" do
    connector.source = nil
    connector.target = nil

    expect(relationship.source_navigable).to be(true)
    expect(relationship.target_navigable).to be(true)
  end

  it "defaults ends without modifiers to navigable" do
    connector.source.modifiers = nil
    connector.target.modifiers = nil

    expect(relationship.source_navigable).to be(true)
    expect(relationship.target_navigable).to be(true)
  end

  it "defaults ends without an extension connector to navigable" do
    relationship_id
    root.extension = nil

    expect(relationship.source_navigable).to be(true)
    expect(relationship.target_navigable).to be(true)
  end
end
