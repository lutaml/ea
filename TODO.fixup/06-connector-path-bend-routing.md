# 06 - Connector Path= Bend Routing

## Status: DONE (2026-07-24)

## Outcome

`ConnectorRouter` now accepts an optional `bend_path:` Array of
[x, y] pairs. When non-empty, the router emits
`[source_point, *bend_path, target_point]` instead of computing
its own L-shaped bend.

`ExtensionGeometryParser#parse_bend_path` extracts EA's `Path=`
field format `x1:y1$x2:y2$...` into Ruby pairs.

`DiagramBuilder#compute_waypoints` plumbs `geom.bend_points`
through to the router.

## Outcome metrics

Polygon count within ±1: 68% → 69% (small improvement from
proper bend routing reducing the marker rendering mismatches).

## Files changed

- `lib/ea/svg/connector_router.rb` — `bend_path:` parameter
- `lib/ea/sources/xmi/extension_geometry_parser.rb` —
  `parse_bend_path` + `bend_points` Placement field
- `lib/ea/sources/xmi/diagram_builder.rb` — passes bend_points to router
