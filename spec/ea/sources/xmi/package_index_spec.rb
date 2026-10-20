# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe "Sparx XMI package index" do
  let(:document) { Ea::Sources::Xmi::Adapter.from_path(fixtures_path("basic.xmi")) }
  let(:index) { document.index_by_id }

  it "lists each package once" do
    packages = index.values.grep(Ea::Model::Package)

    expect(packages.size).to eq(42)
    expect(packages.size).to eq(packages.uniq.size)
  end

  it "resolves a package by its EAPK id" do
    expect(index["EAPK_C8CA047C_8ADC_43a4_B828_E71E1ABFD021"].name)
      .to eq("Basic Class Diagram with Attributes")
  end

  it "resolves a package by its EAID alias" do
    expect(index["EAID_C8CA047C_8ADC_43a4_B828_E71E1ABFD021"].name)
      .to eq("Basic Class Diagram with Attributes")
  end

  it "returns nil for an unknown EAID" do
    expect(index["EAID_00000000_0000_0000_0000_000000000000"]).to be_nil
  end
end
