# frozen_string_literal: true

# Connector slices (bounds, offsets, Path, saved bends) copied from
# 20251010_current_plateau_v5.1.xmi, replayed through Xmi::StoredRoute.
module XmiRouteSliceHelpers
  KEPT_BENDS = {
    "5D6DB5A0" => ["Generalization", { mode: "3", lwidth: "2", tree: "V" }, "Mode=3;LWidth=2;TREE=V;",
                   "1012:-150;962:-150;", [[870, 200, 284, 258], [897, 19, 130, 81]], [[0, 0], [0, 0]], 1,
                   [[1012, 199], [1012, 150], [962, 150], [962, 101]]],
    "00C5C772" => ["Association", { mode: "3", lwidth: "2", tree: "OS" }, "Mode=3;LWidth=2;TREE=OS;",
                   "663:-404;663:-265;", [[701, 380, 100, 80], [306, 231, 203, 125]], [[0, 16], [0, 28]], 4,
                   [[701, 404], [663, 404], [663, 265], [509, 265]]],
    "508A37DC" => ["Generalization", { mode: "3", lwidth: "2", tree: "V" }, "Mode=3;LWidth=2;TREE=V;",
                   "739:-238;730:-238;", [[691, 260, 100, 49], [640, 120, 180, 68]], [[0, 0], [0, 0]], 1,
                   [[739, 259], [739, 238], [730, 238], [730, 189]]],
    "2A339928" => ["Aggregation", { mode: "3", lwidth: "2", tree: "V" }, "Mode=3;LWidth=2;TREE=V;",
                   "320:-716;375:-716;", [[129, 842, 218, 159], [193, 426, 365, 240]], [[82, -12], [0, 0]], 1,
                   [[320, 841], [320, 716], [375, 716], [375, 667]]],
    "ADBA40A1" => ["Generalization", { mode: "1", lwidth: "2", centered_origin_ray: true }, "Mode=1;LWidth=2;",
                   "498:-267;213:-267;", [[382, 124, 191, 105], [120, 136, 130, 81]], [[25, -9], [5, -9]], 4,
                   [[573, 211], [208, 217]]]
  }.freeze

  def box(left, top, width, height)
    Ea::Model::Bounds.new(x: left, y: top, width: width, height: height)
  end

  def points(list)
    list.map { |col, row| Ea::Model::Waypoint.new(position: Ea::Model::Point.new(x: col, y: row)) }
  end

  def xy(point)
    [point.x, point.y]
  end

  def slice(type:, style:, link_style:, path:, **geometry)
    boxes, offsets, edge, waypoints = geometry.values_at(:boxes, :offsets, :edge, :waypoints)
    model = Ea::Model::DiagramConnector.new(connector_type: type, style: style, waypoints: points(waypoints))
    { model: model, link: Ea::Sources::Xmi::StoredRoute::Link.new(link_style, path),
      bounds: { source: box(*boxes[0]), target: box(*boxes[1]) },
      offsets: { source: offsets[0], target: offsets[1] }, edge: edge }
  end

  def run_stage(stage, args)
    Ea::Sources::Xmi::StoredRoute.new.public_send(stage, args[:model], link: args[:link], bounds: args[:bounds],
                                                                       offsets: args[:offsets], edge: args[:edge])
  end
end
