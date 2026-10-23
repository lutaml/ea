# frozen_string_literal: true

module XmiDocumentRoutePreservationHelpers
  def xmi_route_scene(guid)
    document, diagram = plateau_xmi_diagram(guid)
    svg = Ea::Svg::EaEmitter::Document.new(
      diagram, model_index: document.index_by_id, document: document,
      frame: true
    ).render
    native = native_svg_text(diagram.id)
    shifts = rect_anchor_shift(svg, native)
    expect(shifts.size).to eq(1), "element rectangles must establish one SVG translation"
    { diagram: diagram, svg: svg, native: native, shift: shifts.first }
  end

  # The emitter merges adjacent same-style layers and interleaves connector
  # lines with their markers, so a connector's line is not addressable by a
  # line-style group or index. Identify it by the native endpoints (translated
  # into this render's frame) and require exactly one such path; markers and
  # other connectors never share a line's two endpoints.
  def xmi_document_connector_path(scene, guid, native_endpoints)
    xmi_expect_source_connector(scene[:diagram], guid)
    wanted = xmi_scene_endpoints(scene, native_endpoints)
    matches = xmi_drawn_paths(scene).select { |path| xmi_native_endpoints(path) == wanted }
    expect(matches.size).to eq(1), "expected one drawn path between #{wanted.inspect}, got #{matches.size}"
    matches.first
  end

  def xmi_expect_source_connector(diagram, guid)
    index = xmi_source_connector_index(diagram.connectors.select(&:renderable?), guid)
    expect(index).not_to be_nil, "missing source connector #{guid}"
  end

  def xmi_scene_endpoints(scene, native_endpoints)
    native_endpoints.map { |point| point.zip(scene[:shift]).map { |value, shift| value - shift } }.sort
  end

  def xmi_drawn_paths(scene)
    Nokogiri::XML(scene[:svg]).remove_namespaces!.xpath("//path").map { |path| path["d"] }
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
