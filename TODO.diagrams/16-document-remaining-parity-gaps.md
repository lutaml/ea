# TODO-D 16 - Document all remaining parity gaps

## Status: LIVING DOCUMENT (2026-07-27)

## Current parity (QEA-direct, 188 diagrams)

| Metric | Value |
|---|---|
| Within shape-count tolerance | 123/188 (65.4%) |
| Text overlap avg | 62.8% |
| Polygon delta | -166 |
| Path delta | -181 |
| Text delta | -883 |
| Rect delta | -460 |

## Byte-level diff status (maintenance diagram)

The simplest diagram (`maintenance`, 1 classifier) now matches
reference byte-for-byte on:

- Canvas dimensions (254x177) ✓
- Element position (35, 40) ✓
- Background rect dimensions ✓
- Frame border path coordinates ✓

Remaining byte-level differences on maintenance:

### 1. Build ID
- Ours: `Build: 1628`
- Ref: `Build: 1624`

The QEA was authored with build 1628 (newer). The reference SVGs
were exported with build 1624. Either change the BUILD_ID constant
or accept the difference.

### 2. Frame tab width
- Ours: `points="6 26 135 26 148 13 148 6 6 6 6 26"` (width=129)
- Ref:  `points="6 26 86 26 99 12 99 6 6 6 6 26"` (width=80)

EA calculates the tab width from GDI text metrics on the label
"class maintenance". Our calculation uses `label.length * 7 + 10`
which overshoots. Need a better text-width approximation, OR
match EA's hardcoded minimum (80px).

### 3. textLength attribute
- Ours: `textLength="65"`
- Ref:  `textLength="73"`

Same root cause as #2 — text-width approximation differs from
GDI metrics.

### 4. Whitespace formatting
- Ours: extra blank lines between `<g>` blocks
- Ref:  no blank lines, tabs for indentation

Cosmetic only — doesn't affect rendering.

## Aggregate parity gaps (across 188 diagrams)

### Polygon under-rendering (-166)
Source-side diamond markers on Aggregation connectors. The diamond
anchor positions drift from EA because connector SX/SY/EX/EY
interpretation isn't exact. Markers render but at slightly wrong
positions, breaking the per-anchor dedup match.

### Path under-rendering (-181)
EA combines connector line + arrow head into one `<path>` with
multiple `M` sub-paths. We emit them as separate paths. Restructure
`Connectors` renderer to emit combined paths per connector.

### Text under-rendering (-883)
Three categories:
1. Connector label positions (we use default offset; EA records
   exact LLB/LRB boxes in t_diagramlinks.Geometry)
2. Attribute defaults (e.g. `lod: integerBetween0and4 = 1` — we
   drop the `= default_value` part)
3. Stereotype-tagged-value text (we render the «property»
   stereotype label on some diagrams where ref doesn't)

### Rect under-rendering (-460)
Mostly classifier-box compartment rects that EA emits as inner
rects (not paths) for some diagram configurations. Also legend
swatches inside Note elements. Not yet investigated thoroughly.

## Priority order for closing remaining gaps

1. **Combined connector paths** — fixes path -181, no architectural change
2. **QEA geometry parser for LLB/LRB** — fixes most of text -883
3. **Attribute default value rendering** — fixes some text delta
4. **Frame tab width calculation** — fixes byte-diff on simple diagrams
5. **Rect inner-compartment rendering** — fixes rect -460
