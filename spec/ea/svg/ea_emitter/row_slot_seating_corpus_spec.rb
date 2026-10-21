# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

# Issue 135: the unframed canvas puts connector ends and compartment dividers
# in the same space, which used to seat four plateau ends one row (13 px) low.
RSpec.describe Ea::Svg::EaEmitter::ConnectorRedock, "row-slot seating on plateau QEA 5D6DB5A0" do
  include QeaBridgeCorpusHelpers

  before { skip "plateau QEA unavailable" unless File.exist?(plateau_path) }

  let(:svg) do
    document, diagram = plateau_diagram("{5D6DB5A0-5047-4bac-9E60-69904A60B56D}")
    Nokogiri::XML(Ea::Svg::EaEmitter::Document.new(
      diagram, model_index: document.index_by_id, document: document
    ).render).remove_namespaces!
  end

  let(:path_data) { svg.xpath("//path").map { |path| path["d"] } }

  it "keeps the Aggregation end and its role label on the native row" do
    role = svg.xpath("//text").find { |node| node.text == "+ifcRoomAttribute" }

    expect(path_data).to include("M 635 59 L 429 59")
    expect(role["y"]).to eq("79.00")
  end

  it "keeps the horizontal Generalization on the native row" do
    expect(path_data).to include("M 378 520 L 296 520")
    expect(path_data).not_to include("M 378 533 L 296 533")
  end
end
