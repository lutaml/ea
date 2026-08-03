# TODO-D 61: Plateau parity gaps

## Status: open (broad cross-cutting gaps on plateau QEA)

The plateau is the `20251010_current_plateau_v5.1.qea` file at
`examples/qea/`. Its 188 reference SVGs live at
`examples/exports/20251010_current_plateau_v5/Images/`.

A separate plateau XMI is at
`~/src/mn/mn-samples-plateau/sources/xmi/plateau_all_packages_export.xmi`
with its own reference SVGs at
`~/src/mn/mn-samples-plateau/sources/001-mds/xmi-images/`.

## Current state — Plateau QEA (examples/)

| Metric | Before | After improvements | Change |
|--------|--------|-------------------|--------|
| Matched | 126/188 | **130/188** | +4 |
| rect | -460 | **-460** | — |
| path | -455 | **-92** | +363 recovered |
| polygon | +27 | **+27** | — |
| text | -519 | **-519** | — |

Key improvements this session:
- Horizontal-tree-routed arrow suppression (narrower check)
- Marker dedup changed to polygon-only (never dedup arrows)
  → recovered ~200 association arrow paths on plateau

## Current state — Plateau XMI (~/src/mn/)

| Metric | Value |
|--------|-------|
| Diagrams matched (tolerance ≤5) | 127/185 |
| rect delta | -221 (-11.0%) |
| path delta | -338 (-10.2%) |
| polygon delta | -6 (-0.6%) |
| text delta | +97 (+0.6%) |

## Where the deltas come from

### rect -460 (QEA) / -221 (XMI)
- Missing visibility icons (2 rects per attribute × many elements)
- Package-content child rows missing on some diagrams
- Element shape encoding (rect vs polygon)

### path -455 (QEA) / -338 (XMI)
- Connector arrow markers (tree-routed suppression removes some)
- Visibility icon paths (7 per attr × many elements)
- Connector routing encoding differences

### text -519 (QEA) / +97 (XMI)
- QEA has richer data (RunState, more tagged values) but some
  texts are not rendered (instance labels, slot values)
- XMI over-renders some texts (from InstanceSpecification parsing)

## Plan

Each delta spans dozens of diagrams. Improvements require broad
pipeline changes rather than single-diagram fixes.
