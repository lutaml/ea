# frozen_string_literal: true

module NotePenPaintHelpers
  # Renders the refs in paint order (EA paints the highest z_order first).
  def painted_svg(index, *refs)
    elements = refs.each_with_index.map do |ref, i|
      Ea::Model::DiagramElement.new(
        model_element_ref: ref, z_order: refs.size - i,
        bounds: Ea::Model::Bounds.new(x: 10 + (i * 150), y: 10, width: 120, height: 80)
      )
    end
    Ea::Svg::EaEmitter::Document.new(Ea::Model::Diagram.new(elements: elements), model_index: index,
                                                                                 content_anchor: false).render
  end

  def pen_pairs(svg)
    svg.scan(/stroke-linecap:(\w+);stroke-linejoin:(\w+)/).uniq
  end

  def note_pens(svg)
    svg.scan(/<g style="[^"]*?linecap:(\w+);stroke-linejoin:(\w+);[^"]*fill:#DCDCDC/).uniq
  end
end
