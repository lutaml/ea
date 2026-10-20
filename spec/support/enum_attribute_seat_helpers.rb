# frozen_string_literal: true

module EnumAttributeSeatHelpers
  # x of each named text minus the left edge of the classifier that owns it,
  # so the diagram's canvas shift cancels between classifiers.
  def seat_offsets(document, diagram, nodes, owner_texts)
    lefts = diagram.elements.to_h { |e| [document.index_by_id[e.model_element_ref]&.name, e.bounds.x] }
    owner_texts.to_h { |owner, pattern| [owner, text_xs(nodes, pattern).map { |x| x - lefts.fetch(owner) }] }
  end

  def text_xs(nodes, pattern)
    nodes.select { |node| node.text.match?(pattern) }.map { |node| node["x"].to_f }
  end
end
