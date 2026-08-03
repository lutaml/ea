# TODO-D 27: Per-diagram path grouping mode detection

## Problem

EA emits connector paths in two styles:

1. **Grouped** — All same-style paths joined into one `<g>` block
   (matches what we currently do in `LayerSequencer#merge_layers_by_style`).
2. **Per-connector** — Each connector path in its own `<g>` block.

Some diagrams use one mode, others use the other. We always use
grouped, contributing to the -181 path delta.

## Investigation

Tested in StyleEx flags — no obvious "grouped" toggle. EA's
emit-mode decision appears to be runtime/export-time, not stored in
the QEA.

## Empirical Observations

- Grouped-style diagrams: 0 to 5 path-delta diagrams (most match)
- Per-connector-style diagrams: 10-30 path-delta (we're missing 10-30
  `<g>` wrappers)

The discriminator might be:

- Diagram export-time option set in EA GUI at export
- Per-diagram count threshold (more connectors → per-connector)
- User preference cached in some EA-specific location we can't access

## Status

Deferred. Without empirical access to EA's export preferences or a
binary blob in the QEA, the mode detection is speculative.

## Acceptance (when picked up)

- Identify the QEA field or runtime condition that controls grouping.
- Implement a per-diagram detector.
- Wire into LayerSequencer: `grouped: detect_grouped_mode(diagram)`.
- Specs cover: small diagrams → grouped, large diagrams → per-connector.
- Path delta within ±20 of zero.