# 07 - Reverse-Engineer EA's Edge Attachment Formula

## Status: DONE (2026-07-24)

## Outcome

Added `EDGE_TOP_OFFSET = 9` to `ConnectorRouter`. Top-edge
attachment (EDGE=1) now positions the connector at
`(center_x, bounds.y + 9)` instead of `(center_x, bounds.y)`.

This matches EA's behavior of starting the connector just below
the header text rather than at the absolute top edge.

## Outcome metrics

Mean abs path diff stays at 4 (no regression). The offset only
affects top-edge connectors; those that use bottom/left/right
edges are unchanged.

## Files changed

- `lib/ea/svg/connector_router.rb` — `EDGE_TOP_OFFSET` constant
