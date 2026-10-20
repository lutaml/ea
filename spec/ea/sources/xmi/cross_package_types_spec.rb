# frozen_string_literal: true

require "spec_helper"
require "ea"

RSpec.describe "Sparx XMI members typed by a classifier in another package" do
  let(:document) do
    Ea::Sources::Xmi::Adapter.from_path(fixtures_path("cross_package_types.xmi"))
  end
  let(:zone) { document.classifiers.find { |c| c.name == "Zone" } }
  let(:operation) { zone.operations.first }

  it "keeps the saved type name on attributes" do
    expect(zone.properties.first.type_name).to eq("Surface")
  end

  it "keeps the saved type name on operation returns" do
    expect(operation.return_type_name).to eq("Surface")
  end

  it "keeps the saved type name on parameters" do
    expect(operation.parameters.map(&:type_name)).to eq(["Surface"])
  end

  it "still qualifies the owning classifier" do
    expect(zone.qualified_name).to eq("urf::Zone")
  end
end
