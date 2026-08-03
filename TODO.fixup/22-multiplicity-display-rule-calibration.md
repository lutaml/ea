# 22 - Multiplicity Display Rule Calibration

## Status: ANALYZED (2026-07-25, closed)

## Findings

Sampled reference SVGs and observed multiplicity rendering
patterns:

- Most attributes show `[0..1]` or `[0..*]` etc. in brackets
- A few diagrams show attribute text WITHOUT multiplicity
  (e.g., `+ areaType: gml::CodeType`)
- The "no multiplicity" cases appear to be box-fit truncation
  (text was too wide, multiplicity got clipped) rather than
  a display rule

## Decision

Keeping current rule: always render `[lower..upper]` except
when `1..1` (default — omitted). The truncation case is a
rendering artifact we don't need to replicate.

## Files changed

None.
