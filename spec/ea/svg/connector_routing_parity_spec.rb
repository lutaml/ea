# frozen_string_literal: true

require "spec_helper"
require "ea"
require "xmi"

# Checks that connector routing produces visually correct paths
# (2+ waypoints per non-hidden connector) across at least 10
# diagrams from the plateau XMI.
RSpec.describe "Connector routing parity", :visual_regression do
  XMI_PATH = "/Users/mulgogi/src/mn/mn-samples-plateau/sources/xmi/plateau_all_packages_export.xmi"
  REF_DIR = "/Users/mulgogi/src/mn/mn-samples-plateau/sources/001-mds/xmi-images"

  before(:all) do
    skip "Sample XMI not available" unless File.exist?(XMI_PATH)
  end

  let(:document) do
    root = Xmi::Sparx::Root.parse_xml(File.read(XMI_PATH))
    Ea::Sources::Xmi::Adapter.new(root, XMI_PATH).to_document
  end

  it "produces 2+ waypoints for every non-hidden connector across 10 diagrams" do
    checked = 0
    failures = []

    document.diagrams.each do |diagram|
      ref = File.join(REF_DIR, "#{diagram.id}.svg")
      next unless File.exist?(ref)
      next if diagram.connectors.reject(&:hidden).empty?

      diagram.connectors.reject(&:hidden).each do |conn|
        if conn.waypoints.size < 2
          failures << "#{diagram.name}: connector #{conn.id} has #{conn.waypoints.size} waypoints"
        end
      end

      checked += 1
      break if checked >= 10
    end

    expect(failures).to be_empty,
      "#{failures.size} connectors with <2 waypoints:\n#{failures.first(5).join("\n")}"
  end

  it "renders at least 10 diagrams without errors" do
    checked = 0
    document.diagrams.each do |diagram|
      ref = File.join(REF_DIR, "#{diagram.id}.svg")
      next unless File.exist?(ref)

      expect {
        Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id).render
      }.not_to raise_error

      checked += 1
      break if checked >= 10
    end

    expect(checked).to be >= 10
  end
end
