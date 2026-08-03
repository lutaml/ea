# Parity Status (updated 2026-08-02)

## Headline numbers — examples (current)

| QEA | Matched (tol=5) | Matched (tol=0) | rect Δ | path Δ | polygon Δ | text Δ |
|---|---|---|---|---|---|---|
| **basic** | 22/22 | **22/22** | 0 | +6 | -6 | +2 |
| **plateau** | 188/188 | 167/188 | +4 | **0** | -4 | -40 |
| ArcGISWorkspace | 6/6 | — | 0 | 0 | 0 | +1 |
| simple | 2/2 | 2/2 | 0 | 0 | 0 | 0 |
| test | 2/2 | 2/2 | 0 | 0 | 0 | 0 |

Plateau at tighter tolerances:

| tol | matched | % |
|-----|---------|---|
| 5   | 188/188 | 100% |
| 2   | 185/188 | 98.4% |
| 1   | 179/188 | 95.2% |
| 0   | 167/188 | 88.8% |

## Pixel-perfect parity status

- **basic.qea: 100% pixel-perfect** (22/22 at tolerance=0). The
  aggregation arrow fix (commit 4b25abe) closed the last outlier.
- **plateau QEA: 88.8% pixel-perfect** (167/188 at tolerance=0),
  100% within standard tolerance=5.

## Recent parity commits (2026-08-01)

| commit | summary | impact |
|---|---|---|
| ad7b058 | fix: suppress package subtitle when all placed packages share parent | +19 overshoot closed |
| 59dd4f7 | feat: render off-canvas parent classifier as italic header line | -98 → -36 (62 texts closed) |
| c54a391 | docs: TODO-D 71 + 72 | — |
| 4b25abe | fix: aggregation arrow only on reverse-direction | basic 21/22 → 22/22, plateau path +1 → 0 |
| abf2b72 | docs: TODOs 73-79 + is_a? fix + header_lines specs | — |
| f7d33cb | docs: TODO-D 80 — basic triangle polygon investigation | — |

## MDG integration

- Loader, Registry, Adapter wiring all functional
- CityGML MDG (11 stereotypes) and ISO 19103 MDG (12 stereotypes)
  both load successfully
- Properties added = 0 because available MDG files only define
  stereotypes (no class hierarchies). A richer MDG file would
  close the phantom-attribute gap. Documented in TODO-D 70.

## Code-quality rules (all satisfied)

- autoload only — no `require_relative` in lib/
- No doubles in specs — real model instances
- No private `send`, `instance_variable_get/set`, `respond_to?`
- OCP-friendly marker dispatch via `Marker::Registry.register`
- OCP-friendly compartment pipeline (add module to ALL)
- MECE per-domain builders (Package, Classifier, Relationship, etc.)

## Specs

- 1855 examples, 0 failures, 55 pending (3 new specs added)

## Open parity TODOs (all priorities)

- 73: plateau polygon under-render (-4)
- 74: plateau rect over-render (+4)
- 75: plateau text under-render (-36, foreign-package rule too
  aggressive for some diagrams)
- 76: basic polygon/path deltas (per-diagram within tol=5,
  nonzero in aggregate)
- 77: basic text over-render (+2)
- 78: HeaderLines OCP refactor proposal (provider chain)
- 79: architecture backlog
- 80: basic triangle polygon markers (initial hypothesis disproven)
