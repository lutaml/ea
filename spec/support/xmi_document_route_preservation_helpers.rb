# frozen_string_literal: true

module XmiDocumentRoutePreservationHelpers
  def xmi_route_scene(guid)
    document, diagram = plateau_xmi_diagram(guid)
    svg = Ea::Svg::EaEmitter::Document.new(
      diagram, model_index: document.index_by_id, document: document
    ).render
    native = native_svg_text(diagram.id)
    shifts = rect_anchor_shift(svg, native)
    expect(shifts.size).to eq(1), "element rectangles must establish one SVG translation"
    { diagram: diagram, svg: svg, native: native, shift: shifts.first }
  end

  def xmi_solid_connectors(diagram)
    connectors = diagram.connectors.select(&:renderable?)
    expect(connectors.map(&:connector_type).uniq - %w[Association Generalization Aggregation]).to be_empty
    widths = connectors.map { |connector| Ea::Svg::EaEmitter::Connectors.stroke_width_for(connector, 2) }
    expect(widths.uniq).to eq([2])
    connectors
  end

  # Connector lines precede their markers within each merged line-style group.
  # Restrict this selector to solid, default-width corpus associations.
  def xmi_connector_line_paths(scene, count)
    style = Ea::Svg::EaEmitter::Connectors.new(scene[:diagram]).line_style
    groups = Nokogiri::XML(scene[:svg]).remove_namespaces!.xpath("//g[@style='#{style}'][count(path)>=#{count}]")
    expect(groups.size).to eq(1), "expected one solid connector line-style group"
    groups.first.xpath("./path").first(count)
  end

  def xmi_document_connector_path(scene, guid)
    connectors = xmi_solid_connectors(scene[:diagram])
    lines = xmi_connector_line_paths(scene, connectors.size)
    expect(lines.size).to eq(connectors.size)
    index = xmi_source_connector_index(connectors, guid)
    expect(index).not_to be_nil, "missing source connector #{guid}"
    lines.fetch(index)["d"]
  end

  def xmi_source_connector_index(connectors, guid)
    key = guid.upcase.tr("-", "_")
    connectors.index { |connector| connector.relationship_ref.upcase.include?(key) }
  end

  def xmi_path_commands(path)
    expect(path.scan(/[A-Za-z]/) - %w[M L A]).to be_empty
    path.scan(/([MLA])\s+([^MLA]+)/).map do |command, arguments|
      [command, arguments.split.map(&:to_f)]
    end
  end

  def xmi_arc_centers(commands)
    commands.each_cons(2).filter_map do |(_previous_command, previous), (command, arguments)|
      next unless command == "A"

      expect(arguments.first(2).map(&:abs)).to eq([6, 6])
      previous.last(2).zip(arguments.last(2)).map { |start, finish| (start + finish) / 2 }
    end.sort
  end

  def xmi_route_geometry(path)
    commands = xmi_path_commands(path)
    segments = commands.reject { |command, _arguments| command == "M" }
    { endpoints: [commands.first.last.last(2), segments.last.last.last(2)].sort,
      segment_count: segments.size, arcs: xmi_arc_centers(commands) }
  end

  def xmi_native_route(scene, endpoints)
    paths = Nokogiri::XML(scene[:native]).remove_namespaces!.xpath("//path[@shape-rendering='auto']")
    matches = paths.map { |path| path["d"] }.select { |path| xmi_native_endpoints(path) == endpoints.sort }
    expect(matches.size).to eq(1), "native route endpoints must identify one path"
    xmi_route_geometry(matches.first)
  end

  def xmi_native_endpoints(path)
    return unless path.match?(/\AM /) && !path.match?(/[BCQZ]/i)

    commands = path.scan(/[MLA]\s+([^MLA]+)/).flatten
    [commands.first.split.first(2).map(&:to_f), commands.last.split.last(2).map(&:to_f)].sort
  end

  def xmi_native_coordinates(points, shift)
    points.map { |x, y| [x + shift[0], y + shift[1]] }.sort
  end
end
