# frozen_string_literal: true

module XmiShowNotesHelpers
  def basic_show_notes(adapter, path)
    document = QeaBridgeCorpusHelpers.document_for(adapter, File.expand_path("../../#{path}", __dir__))
    document.diagrams.to_h { |diagram| [diagram.name, diagram.show_notes] }
  end
end
