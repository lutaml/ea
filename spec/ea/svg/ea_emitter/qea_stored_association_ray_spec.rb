# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA stored Association ray docking" do
  include QeaCompartmentFontHelpers

  it "keeps the published diagonal ray where it passes the compact header divider" do
    document = public_compartment_document
    diagram = document.diagrams.find { |entry| entry.connectors.any? { |c| c.id == "dc:93:500" } }
    connector = diagram.connectors.find { |entry| entry.id == "dc:93:500" }
    svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id,
                                                    document: document).render
    paths = Nokogiri::XML(svg).css("path").map { |node| node["d"] }

    expect(connector.style[:stored_association_ray]).to be(true)
    # Published endpoints (698,477)/(629,482), translated by the diagram frame.
    expect(paths).to include("M 723 507 L 654 512")
  end
end
