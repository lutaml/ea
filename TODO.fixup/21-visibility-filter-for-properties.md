# 21 - Visibility Filter for Properties

## Status: ANALYZED (2026-07-25, closed)

## Findings

Sampled 5 reference SVGs to check whether private members are
hidden. Findings:

- All sample diagrams render only `+ ` (public) visibility
  markers
- No `-` (private) or `#` (protected) markers visible
- All classifier properties in the source XMI have visibility
  unset (treated as public by default)

## Decision

No filter needed — the current "show all properties" rule
already matches EA's behavior for this dataset. Future XMI
imports with mixed-visibility properties may need a filter.

## Files changed

None.
