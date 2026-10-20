# frozen_string_literal: true

require "tempfile"

module XmiHideParentsHelpers
  FIXTURE = File.expand_path("../fixtures/basic.xmi", __dir__)
  DIAGRAM_MARKER = %(<diagram xmi:id="EAID_6D0349D5_3F1B_4b28_82D2_910743DEB5E5">)
  PARENT_REF = "EAID_370AB08A_207C_4b02_A1C1_5EC1991F32F9"

  def parents_by_name(adapter, path)
    document = QeaBridgeCorpusHelpers.document_for(adapter, File.expand_path("../#{path}", __dir__))
    document.diagrams.map { |diagram| [diagram.name, diagram.show_parents] }
  end

  def render_without_parent(hide_parents:)
    Tempfile.create(["hide-parents", ".xmi"]) do |file|
      file.write(fixture_xml(hide_parents))
      file.flush
      document = Ea::Sources::Xmi::Adapter.from_path(file.path)
      diagram = parent_less_diagram(document)
      [diagram.show_parents, ghost_count(diagram, document)]
    end
  end

  private

  def fixture_xml(hide_parents)
    head, tail = File.read(FIXTURE).split(DIAGRAM_MARKER, 2)
    tail = tail.sub("HideParents=0", "HideParents=1") if hide_parents
    head + DIAGRAM_MARKER + tail
  end

  def parent_less_diagram(document)
    diagram = document.diagrams.find { |d| d.name == "Composition with Substitution" }
    diagram.elements = diagram.elements.reject { |e| e.model_element_ref == PARENT_REF }
    diagram
  end

  def ghost_count(diagram, document)
    svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id, document: document).render
    svg.scan(%r{<text[^>]*>([^<]*)</text>}).flatten.count("Class B")
  end
end
