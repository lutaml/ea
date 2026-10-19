# frozen_string_literal: true

require "spec_helper"

RSpec.describe "QEA note font fallback isolation" do
  let(:arcgis_font_document) do
    path = File.expand_path("../../../../examples/qea/ArcGISWorkspace_template.qea", __dir__)
    Ea::Sources::Qea::Adapter.new(cached_qea_database(path), path).to_document
  end

  it "keeps ArcGIS diagram1 packages and diagram4 tagged classifier on native Cambria" do
    document = arcgis_font_document
    diagrams = document.diagrams.select do |diagram|
      %w[7D960BD8-65D8-4934-9C11-4EF860DD8FBA 7C44AC09-27C1-47b3-9A85-88EC71C081FF].include?(diagram.id)
    end
    families = diagrams.flat_map do |diagram|
      svg = Ea::Svg::EaEmitter::Elements.new(diagram, model_index: document.index_by_id,
                                                      document: document).render
      nodes = Nokogiri::XML("<svg>#{svg}</svg>").css("text")
      nodes.select { |node| ["Association Classes", "tags"].include?(node.text) }
           .map { |node| node["style"][/font-family:([^;]+)/, 1] }
    end

    expect(families).to eq(%w[Cambria Cambria])
  end
end

RSpec.describe "Explicit font preservation beside notes" do
  it "preserves explicit Arial notes and classifiers while excluding notes as fallback donors" do
    note = Ea::Model::DiagramElement.new(id: "note", model_element_ref: "n", font_family: "Arial")
    explicit = Ea::Model::DiagramElement.new(id: "explicit", font_family: "Arial")
    plain = Ea::Model::DiagramElement.new(id: "plain")
    diagram = Ea::Model::Diagram.new(id: "d", elements: [note, plain])
    resolver = Ea::Svg::EaEmitter::FontResolver.new(diagram, model_index: { "n" => Ea::Model::Note.new(id: "n") })

    expect([resolver.family_for(note), resolver.family_for(explicit), resolver.family_for(plain)])
      .to eq(%w[Arial Arial Cambria])
  end
end
