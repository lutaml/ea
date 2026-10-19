# frozen_string_literal: true

module QeaPackageTabWidthHelpers
  def package_width_document(fixture)
    path = File.expand_path("../../examples/qea/#{fixture}.qea", __dir__)
    Ea::Sources::Qea::Adapter.new(cached_qea_database(path), path).to_document
  end

  def package_tab_widths(document, diagram_id)
    emitter = package_elements(document, diagram_id)
    xml = Nokogiri::XML("<svg>#{emitter.render}</svg>")
    xml.xpath("//g[polygon][text]").to_h do |group|
      [group.css("text").last.text, package_tab_width(group)]
    end
  end

  def package_elements(document, diagram_id)
    diagram = document.diagrams.find { |entry| entry.id == diagram_id }
    Ea::Svg::EaEmitter::Elements.new(diagram, model_index: document.index_by_id, document: document)
  end

  def package_tab_width(group)
    points = group.css("polygon").last["points"].split.map(&:to_f)
    points[2] - points[0]
  end
end
