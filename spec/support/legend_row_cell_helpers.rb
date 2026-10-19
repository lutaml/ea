# frozen_string_literal: true

module LegendRowCellHelpers
  def source_legend_row_cell(document:, diagram_guid:, object_guid:)
    diagram = source_diagram(document, diagram_guid)
    placement = source_placement(diagram, object_guid)
    legend = document.index_by_id.fetch(placement.model_element_ref).legend
    svg = rendered_diagram(document, diagram)
    [placement, legend, svg]
  end

  def source_legend_row_cell_offsets(svg, placement, legend)
    bounds = placement.bounds
    legend.items.map.with_index do |item, index|
      legend_row_cell_offset(svg, source_legend_icon(svg, bounds, index), item)
    end
  end

  def synthetic_legend_row_cell(size:, unit:, logical_height:)
    legend = synthetic_legend
    context = synthetic_legend_context(legend, size, unit, logical_height)
    svg = Nokogiri::XML("<svg>#{Ea::Svg::EaEmitter::Compartment::Shape.render(context)}</svg>")
    [legend, svg]
  end

  def legend_row_cell_offsets(svg, legend)
    icons = svg.css("rect[width='17'][height='17']")
    raise "Legend icon count does not match items" unless icons.length == legend.items.length

    legend.items.map.with_index do |item, index|
      legend_row_cell_offset(svg, icons[index], item)
    end
  end

  private

  def legend_row_cell_offset(svg, icon, item)
    labels = svg.css("text").select { |text| text.text == item.name }
    raise "Expected one legend label for #{item.name}" unless labels.one?

    label = labels.first
    [label["y"].to_f - icon["y"].to_f, label]
  end

  def format_coordinate(value)
    format("%.2f", value).sub(/\.?0+\z/, "")
  end

  def source_diagram(document, diagram_guid)
    document.diagrams.find { |entry| entry.id.casecmp?(diagram_guid) }
  end

  def source_placement(diagram, object_guid)
    diagram.elements.find { |entry| entry.model_element_ref.casecmp?(object_guid) }
  end

  def rendered_diagram(document, diagram)
    output = Ea::Svg::EaEmitter::Elements.new(
      diagram, model_index: document.index_by_id, document: document
    ).render
    Nokogiri::XML("<svg>#{output}</svg>")
  end

  def source_legend_icon(svg, bounds, index)
    x = format_coordinate(bounds.x + 10)
    y = format_coordinate(bounds.y + 30 + (19 * index))
    icons = svg.css("rect[width='17'][height='17']").select do |rect|
      rect["x"] == x && rect["y"] == y
    end
    raise "Expected one source legend icon at #{x},#{y}" unless icons.one?

    icons.first
  end

  def synthetic_legend
    Ea::Model::Legend.new(title: "Legend", heading_size: 16,
                          items: [Ea::Model::LegendItem.new(name: "WWW")])
  end

  def synthetic_legend_context(legend, size, unit, logical_height)
    element = Ea::Model::DiagramElement.new(font_size: size, font_logical_height: logical_height)
    Ea::Svg::EaEmitter::RenderContext.new(
      bounds: Ea::Model::Bounds.new(x: 100, y: 50, width: 194, height: 120),
      element: element, model_element: Ea::Model::Note.new(legend: legend),
      family: "Carlito", size: size, size_unit: unit, logical_height: logical_height
    )
  end
end
