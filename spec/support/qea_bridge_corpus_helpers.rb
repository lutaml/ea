# frozen_string_literal: true

module QeaBridgeCorpusHelpers
  # Parse each immutable corpus once per process, but give every example its
  # own document so rendering or mutations cannot leak into another example.
  def self.document_for(adapter, path)
    stat = File.stat(path)
    key = [adapter, File.expand_path(path), stat.size, stat.mtime]
    @documents ||= {}
    bytes = @documents[key] ||= Marshal.dump(adapter.from_path(path))
    # Only deserialize bytes created above from trusted fixtures in this process.
    Marshal.load(bytes) # rubocop:disable Security/MarshalLoad
  end

  def plateau_path
    File.expand_path("../../examples/qea/20251010_current_plateau_v5.1.qea", __dir__)
  end

  def plateau_diagram(guid)
    @plateau ||= QeaBridgeCorpusHelpers.document_for(Ea::Sources::Qea::Adapter, plateau_path)
    id = Ea::Sources::Qea::IdNormalizer.from_guid(guid)
    [@plateau, @plateau.diagrams.find { |diagram| diagram.id == id }]
  end

  def rendered_arc_seats(guid)
    document, diagram = plateau_diagram(guid)
    svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id, document: document).render
    paths = Nokogiri::XML(svg).remove_namespaces!.xpath("//path").map { |path| path["d"] }
    paths.flat_map { |d| arc_seats(d) }.sort
  end

  def arc_seats(path_data)
    path_data.scan(/A [\d.-]+ [\d.-]+ [\d.-]+ \d \d ([\d.-]+) ([\d.-]+)/).map do |x, y|
      [x.to_f.round, y.to_f.round]
    end
  end

  def connector_by_id(diagram, connector_id)
    diagram.connectors.find { |connector| connector.paint_order&.last == connector_id }
  end

  def plateau_xmi_path
    ENV.fetch("EA_PLATEAU_XMI") do
      File.expand_path("../../../lutaml/examples/xmi/20251010_current_plateau_v5.1.xmi", __dir__)
    end
  end

  def plateau_xmi_diagram(guid)
    @plateau_xmi ||= QeaBridgeCorpusHelpers.document_for(Ea::Sources::Xmi::Adapter, plateau_xmi_path)
    key = ->(value) { value.to_s.upcase.gsub(/[{}_-]/, "") }
    [@plateau_xmi, @plateau_xmi.diagrams.find { |diagram| key.call(diagram.id).include?(key.call(guid)) }]
  end

  def xmi_rank(diagram, connector_guid)
    key = connector_guid.upcase.delete("{}").tr("-", "_")
    diagram.connectors.find { |connector| connector.relationship_ref.to_s.upcase.include?(key) }.paint_order
  end

  def xmi_arc_paths(guid)
    document, diagram = plateau_xmi_diagram(guid)
    svg = Ea::Svg::EaEmitter::Document.new(diagram, model_index: document.index_by_id, document: document).render
    Nokogiri::XML(svg).remove_namespaces!.xpath("//path").map { |path| path["d"] }.select { |d| d.include?(" A ") }
  end
end
