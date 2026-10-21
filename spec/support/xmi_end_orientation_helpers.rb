# frozen_string_literal: true

module XmiEndOrientationHelpers
  FIXTURE = File.expand_path("../fixtures/stored_bend_end_orientation.xmi", __dir__)

  def oriented_document(xml = File.read(FIXTURE))
    root = ::Xmi::Sparx::Root.parse_xml(xml)
    Dir.mktmpdir do |dir|
      path = File.join(dir, "oriented.xmi")
      File.write(path, xml)
      Ea::Sources::Xmi::Adapter.new(root, path).to_document
    end
  end

  def oriented_connectors(document)
    document.diagrams.first.connectors.to_h do |connector|
      [connector.relationship_ref[5, 8], connector]
    end
  end

  def waypoint_pairs(connector)
    connector.waypoints.map { |waypoint| [waypoint.position.x, waypoint.position.y] }
  end

  def multiplicity_seats(document)
    svg = Ea::Svg::EaEmitter::Document.new(
      document.diagrams.first, model_index: document.index_by_id, document: document
    ).render
    svg.scan(%r{<text x="([-\d.]+)" y="([-\d.]+)"[^>]*>(1|0\.\.1)</text>}).map do |x, y, text|
      [text, x.to_f, y.to_f]
    end
  end

  # The last occurrence: later connectors draw after earlier ones.
  def text_seats(document, *texts)
    svg = Ea::Svg::EaEmitter::Document.new(
      document.diagrams.first, model_index: document.index_by_id, document: document
    ).render
    texts.to_h do |text|
      x, y = svg.scan(%r{<text x="([-\d.]+)" y="([-\d.]+)"[^>]*>#{Regexp.escape(text)}</text>}).last
      [text, [x.to_f, y.to_f]]
    end
  end

  def self_association_xml
    File.read(FIXTURE)
        .sub(/(<connector xmi:idref="EAID_07034165.*?<target xmi:idref=")[^"]+/m,
             '\\1EAID_1FFA9854_10E5_47a7_BE3E_4447F57FE997')
        .sub(/(subject="EAID_07034165[^>]*?)SOID=BBBF777B/, '\\1SOID=944E6234')
  end
end
