# frozen_string_literal: true

module XmiDiagramFlagHelpers
  def basic_diagram_flags(adapter, path)
    document = QeaBridgeCorpusHelpers.document_for(adapter, File.expand_path("../../#{path}", __dir__))
    document.diagrams.map do |diagram|
      [diagram.name, diagram.show_package_contents ? true : false, diagram.show_foreign ? true : false]
    end
  end
end
