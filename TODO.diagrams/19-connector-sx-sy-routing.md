# 19 - Connector Source/Target Edge Routing from SX/SY/EX/EY

## Status: DONE (2026-07-23)

## Outcome

`ConnectorRouter` now accepts `source_delta` and `target_delta`
(defaulting to [0,0]). `DiagramBuilder#compute_waypoints` passes
SX/SY/EX/EY from the parsed geometry to the router, which applies
them as deltas to the edge-attachment point.

`ExtensionGeometryParser.Placement` already exposed `sx`, `sy`,
`ex`, `ey` — just plumbs them through.

## Remaining diff

Waterway connectors still show ~20 px y-offset vs EA reference
(643 vs 663). The SX/SY deltas are small (-21 to 150) and don't
account for this gap. EA likely uses a different attachment
formula (not strict edge center) — possibly offset by half
font-height or other rendering consideration. Deferred to deeper
reverse-engineering.

## Files changed

- `lib/ea/svg/connector_router.rb` — source_delta / target_delta support
- `lib/ea/sources/xmi/diagram_builder.rb` — passes deltas to router
