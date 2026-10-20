# frozen_string_literal: true

require "spec_helper"
require "xmi"

RSpec.shared_context "Plateau import source" do
  # Reduced from 20251010_current_plateau_v5.1.xmi: the two package diagrams,
  # their package/import records, extension connectors and original UMLDI routes.
  let(:path) { fixtures_path("plateau_imports.xmi") }
  let(:xml) { File.read(path) }
  let(:root) { Xmi::Sparx::Root.parse_xml(xml) }
  let(:document) { described_class.new(root, path).to_document }
  let(:import_id) { "EAID_8F6BFB6E_4246_46f5_A6B7_A5DAB33B520F" }
end

RSpec.describe Ea::Sources::Xmi::Adapter, "Plateau import captions" do
  include_context "Plateau import source"

  it "loads element imports recorded as dependency connectors with their endpoints" do
    expect(document.relationships.find do |rel|
      rel.id == import_id
    end).to be_a(Ea::Model::Dependency).and have_attributes(
      stereotype: "import",
      client_id: "EAID_D0BD0C75_6B1B_4575_9419_A7D39C74DB71",
      supplier_id: "EAID_9E3ECCD9_5472_45ce_BE7A_BC004A52B63C"
    )
    expect(document.relationships.size).to eq(7)
  end

  it "renders all five and three import captions from the actual source diagrams" do
    counts = document.diagrams.map do |diagram|
      svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id,
                                                      document: document).render
      Nokogiri::XML(svg).xpath("//*[local-name()='text']").count { |node| node.text == "«import»" }
    end

    expect(counts).to eq([5, 3])
  end
end

RSpec.describe Ea::Sources::Xmi::Adapter, "Plateau import preservation" do
  include_context "Plateau import source"

  it "preserves existing Package imports as associations" do
    imports = document.relationships.grep(Ea::Model::Association)

    expect(imports.size).to eq(4)
    expect(imports).to all(have_attributes(stereotype: "import", source_navigable: false,
                                           target_navigable: true))
  end

  context "when the dependency is already defined in the UML model" do
    let(:xml) do
      super().sub('elementImport xmi:type="uml:ElementImport"',
                  'packagedElement client="original-client" supplier="original-supplier" xmi:type="uml:Dependency"')
    end

    it "retains the model definition without duplicating its id" do
      imports = document.relationships.select { |rel| rel.id == import_id }

      expect(imports.size).to eq(1)
      expect(imports.first).to have_attributes(client_id: "original-client", supplier_id: "original-supplier")
    end
  end
end

RSpec.describe Ea::Sources::Xmi::Adapter, "unsupported extension connectors" do
  include_context "Plateau import source"

  context "when a dependency connector is not an import" do
    before do
      root.extension.connectors.connector.find { |connector| connector.idref == import_id }.xrefs = nil
    end

    it "does not invent an unsupported extension-only relationship" do
      expect(document.relationships.map(&:id)).not_to include(import_id)
    end
  end
end
