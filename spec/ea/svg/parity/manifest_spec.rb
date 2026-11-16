# frozen_string_literal: true

require "spec_helper"
require "yaml"

RSpec.describe "Parity diagram manifest" do
  let(:root) { File.expand_path("../../../..", __dir__) }
  let(:manifest) do
    YAML.safe_load_file(File.join(root, "spec/fixtures/parity/manifest.yml"))
  end
  let(:entries) { manifest.fetch("diagrams") }
  let(:document) do
    Ea::Sources::Qea::Adapter.from_path(File.join(root, manifest.fetch("model")))
  end

  it "identifies distinct diagrams in the QEA document with export names and coverage" do
    expect(entries).not_to be_empty
    expect(entries.map { |entry| entry.fetch("guid") }.uniq.size).to eq(entries.size)
    diagrams = document.diagrams.to_h { |diagram| [diagram.id, diagram] }

    entries.each do |entry|
      guid = entry.fetch("guid")
      id = Ea::Sources::Qea::IdNormalizer.from_guid(guid)
      aggregate_failures(guid) do
        expect(diagrams).to have_key(id)
        expect(diagrams[id]&.name).to eq(entry.fetch("name"))
        expect(entry.fetch("eaid")).to eq(Ea::Sources::Qea::IdNormalizer.to_eaid(guid))
        expect(entry.fetch("covers")).not_to be_empty
      end
    end
  end
end
