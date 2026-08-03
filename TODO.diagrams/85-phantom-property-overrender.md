# TODO-D 85: Phantom connector «property» over-render on selected diagrams

## Status: open

Several plateau diagrams over-render the «property» stereotype
text (and associated role + multiplicity labels) for PHANTOM
Aggregation connectors — synthesized when both endpoints are
placed but no t_diagramlinks entry exists.

## Per-diagram «property» delta

| Diagram | Ours | Ref | Diff |
|---|---|---|---|
| indoor | 10 | 10 | 0 ✓ |
| brid_1 | 12 | 11 | +1 |
| CityGMLCore | 4 | 2 | +2 |
| veg | 16 | 11 | +5 |

## What's known

- Phantom Aggregation connectors get `DEFAULT_LABEL_BOXES`
  (LLT/LLB geometry) in `DiagramBuilder#build_phantom_connector`.
- This geometry triggers `EndLabel#texts` to emit role +
  «property» + multiplicity labels.
- The `property_label?` check gates on direction
  ("Source -> Destination" or "Destination -> Source" → render;
  "Unspecified" / "Bi-Directional" → suppress).
- On indoor, all 9 phantom Aggregations with non-empty
  SourceRole correctly render «property» in ref.
- On brid_1, 3 phantom Aggregations have non-empty SourceRole
  but ref renders «property» for only 2 of them.

## Discriminator candidates (untested)

1. Source class stereotype — maybe «dataType» sources render
   «property» but other stereotypes don't.
2. Source class's attribute compartment visibility — maybe
   sources with hidden attribute compartments don't render
   «property» labels.
3. Destination class's attribute compartment — similar.
4. A specific t_connector flag (SourceAccess, DestAccess,
   Pursposes, etc.) that we don't yet parse.
5. Connector has a Style flag indicating label visibility.

## Investigation update (2026-08-02)

brid_1's over-render is NOT from phantom connectors — brid_1
has 11 EXPLICIT t_diagramlinks for Aggregations. The over-render
is from the role-fallback logic in `EndLabel#texts`:

  Connector 424 (DataQualityAttribute -> _AbstractBridge):
    - Geometry has LLT/LLB (source end) AND LRT (target end)
    - SourceRole = "bridDataQualityAttribute"
    - DestRole = empty

  My code:
    - Source end: LLT present + role present → renders role + «property»
    - Target end: LRT present + role empty → FALLBACK to source role
      → renders role + «property» AGAIN at LRT position

  Ref:
    - Source end: renders role + «property» (matches my code)
    - Target end: NOTHING (despite LRT geometry present)

## Tested fix (REVERTED)

Tried restricting role fallback to only fire when text_box is
also missing. Result: text delta went from -40 to -154 — the
fallback is needed for many OTHER cases (114 valid labels rely
on it).

## The actual discriminator (needed)

EA likely considers LRT geometry "stale" when:
  - The geometry has unusual offset (e.g., OY=315 for connector
    424, vs typical ±50)
  - OR the connector's direction makes the target end non-navigable

The "unusual offset" rule is fragile. A more principled rule
would require parsing additional t_diagramlinks fields or
comparing against EA's internal "dirty" flag.

## Strategy

For each affected diagram, identify which connectors have LRT
geometry but no target role, and trace the LRT offset. If a
threshold rule (e.g., |OY| > 100) cleanly separates valid from
invalid, apply it.

## Related

  - TODO-D 75: plateau text under-render (current -40)
  - TODO-D 81: plateau path over-render
  - lib/ea/svg/ea_emitter/label/end_label.rb (property_label?)
  - lib/ea/sources/qea/diagram_builder.rb (DEFAULT_LABEL_BOXES)
