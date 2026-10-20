# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ea::Sources::Xmi::ExtensionElements do
  let(:row) { double(subject: "connector", geometry: "SX=0;SY=0;EX=0;EY=0;Path=;", style: ";Hidden=0;") }
  let(:diagram) { double(elements: double(element: [row])) }

  it "recognizes a connector using the source index when DUIDs are absent" do
    placements = described_class.new(diagram, connector_subjects: { "connector" => true })
    expect(placements.placed_connectors.map(&:subject)).to eq(["connector"])
  end

  it "does not infer an unknown row is a connector" do
    expect(described_class.new(diagram).placed_connectors).to be_empty
  end

  it "preserves connector recognition from explicit DUIDs" do
    allow(row).to receive(:style).and_return("SOID=source;EOID=target;")
    expect(described_class.new(diagram).placed_connectors.map(&:subject)).to eq(["connector"])
  end
end
