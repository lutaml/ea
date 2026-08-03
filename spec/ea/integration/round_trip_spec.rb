# frozen_string_literal: true

require "spec_helper"

# End-to-end stability: parse → serialize → re-parse should produce
# equivalent model counts.
RSpec.describe "Round-trip stability" do
  let(:db) { Ea.parse("examples/qea/basic.qea") }

  it "QEA → JSON → re-imported counts match (every collection)" do
    json = Ea::Export::Json::Generator.call(db)
    expect(json).not_to be_empty

    parsed = JSON.parse(json)
    collections = parsed["collections"]
    db.collections.each do |name, records|
      expect(collections[name.to_s].size).to eq(records.size),
        "collection #{name}: serialized #{records.size}, deserialized #{collections[name.to_s].size}"
    end
  end

  it "QEA → XMI produces valid XML structure" do
    xmi = Ea::Transformers.qea_to_xmi(db)
    expect(xmi).to include("<xmi:XMI")
    expect(xmi).to include("<xmi:Documentation")
    expect(xmi).to include("</xmi:XMI>")
  end

  it "lutaml-model to_hash round-trips for EaObject" do
    obj = db.collections[:objects].first
    hash = obj.to_hash
    expect(hash).to be_a(Hash)
    expect(hash["name"]).to eq(obj.name)
  end

  it "lutaml-model to_hash round-trips for EaAttribute" do
    attr = db.collections[:attributes].first
    hash = attr.to_hash
    expect(hash["name"]).to eq(attr.name)
  end

  it "lutaml-model to_hash round-trips for EaPackage" do
    pkg = db.collections[:packages].first
    hash = pkg.to_hash
    expect(hash["name"]).to eq(pkg.name)
  end

  it "lutaml-model to_hash round-trips for EaConnector" do
    conn = db.collections[:connectors]&.first
    skip "no connectors in fixture" unless conn

    hash = conn.to_hash
    expect(hash["name"]).to eq(conn.name) if conn.name
  end

  it "lutaml-model to_hash round-trips for EaXref" do
    xref = db.collections[:xrefs]&.first
    skip "no xrefs in fixture" unless xref

    hash = xref.to_hash
    expect(hash["description"]).to eq(xref.description) if xref.description
  end

  it "Ea::Diff::Comparator treats a model as identical to itself" do
    comparator = Ea::Diff::Comparator.new(db, db)
    expect(comparator.identical?).to be(true)
  end
end
