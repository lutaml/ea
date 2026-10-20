# frozen_string_literal: true

require "spec_helper"
require "xmi"
require "tempfile"
require "ea/sources/xmi/reception_builder"

RSpec.describe "XMI reception ingestion" do
  let(:path) { fixtures_path("basic.xmi") }

  include XmiReceptionHelpers

  it "preserves the three Basic source receptions and the twelve ordinary operations" do
    root = Xmi::Sparx::Root.parse_xml(File.read(path))
    document = Ea::Sources::Xmi::Adapter.new(root, path).to_document
    ordinary = document.classifiers.flat_map(&:operations).reject(&:is_reception)
    grouped = Ea::Sources::Xmi::ReceptionBuilder.new(path).grouped_by_owner
    expected = reception_source_contracts

    expect(grouped.keys).to match_array(expected.map(&:first))
    expected.each do |owner_id, id, name|
      owner = document.classifiers.find { |classifier| classifier.id == owner_id }
      expect(grouped.fetch(owner_id).size).to eq(1)
      reception = grouped.fetch(owner_id).first
      expect(reception).to be_a(Ea::Model::Operation)
      expect(reception).to have_attributes(
        id: id, owner_id: owner.id, name: name,
        qualified_name: "#{owner.name}::#{name}", is_reception: true,
        visibility: "public", is_static: false, is_abstract: false,
        return_type_name: nil, parameters: []
      )
    end
    expect(ordinary.size).to eq(12)
    expect(ordinary.map(&:return_type_name).uniq).to eq(["void"])
    expect(ordinary.map { |operation| operation.parameters.map(&:type_name) }.uniq).to eq([["int"]])
  end
end

RSpec.describe "XMI reception source guards" do
  let(:builder_class) { Ea::Sources::Xmi::ReceptionBuilder }

  it "returns no receptions without a source path" do
    expect(builder_class.new(nil).grouped_by_owner).to eq({})
  end

  it "returns no receptions from a source without receptions" do
    expect(builder_class.new(fixtures_path("datatype_generalization.xmi")).grouped_by_owner).to eq({})
  end
end

RSpec.describe "XMI reception visibility" do
  include XmiReceptionHelpers

  it "preserves visibility, falls back to extension scope, and defaults to public" do
    Tempfile.create(["receptions", ".xmi"]) do |file|
      file.write(reception_visibility_xml)
      file.flush
      grouped = Ea::Sources::Xmi::ReceptionBuilder.new(file.path).grouped_by_owner
      expect(grouped.keys).to eq(["MixedCase"])
      expect(grouped.fetch("MixedCase").map(&:visibility)).to eq(%w[private private public])
      expect(grouped.fetch("MixedCase").first).to have_attributes(
        id: "MixedCase:reception:Private signal", owner_id: "MixedCase",
        name: "Private signal", visibility: "private", is_reception: true
      )
    end
  end
end
