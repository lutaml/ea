# 39 - StyleEx Flag Honoring

## Status: PARTIAL (infrastructure ready, flags not yet honored)

## Infrastructure

Diagram#style_ex_flags parses StyleEx into Hash. Ready to use.

## Flags not yet honored

- SuppressFOC=1 → skip attr/op compartments
- AttPub/Pri/Pro=0 → hide visibility-filtered attrs
- ShowBorder=0 → suppress diagram frame
- ShowNotes=0 → hide element notes
- SuppConnectorLabels=1 → hide connector labels

## Decision

Each flag adds rendering complexity. Will be implemented as
needed when specific QEAs require them. The QEA loader wiring
(carrying StyleEx from QEA through to Diagram) is a prerequisite.

## Files changed

None — Diagram.style_ex_flags already in place (TODO 32).
