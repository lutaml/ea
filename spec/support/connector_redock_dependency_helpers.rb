# frozen_string_literal: true

module ConnectorRedockDependencyHelpers
  def dependency_end_route(type, ids, **options)
    fixture = redock_fixture(type: type, width: "0", style: { mode: "3" },
                             points: [[600, 260], [260, 260]],
                             anchors: [[666, 260], [326, 260]], **boxes, **options)
    fixture[:model_index] = { "r" => relationships.fetch(type).call(ids) }
    redock_output(fixture).first
  end

  def dependency_trunk_route(tree, points, source:, target:, **style)
    type = style.delete(:type) || "Dependency"
    fixture = redock_fixture(type: type, width: "0", style: { mode: "3", tree: tree }.merge(style),
                             points: points, source: source, target: target,
                             anchors: [[0, 0], [1, 1]])
    redock_output(fixture).first
  end
end
