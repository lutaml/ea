# TODO-D 17: Remaining Parity Gaps

## Current State (2026-07-26)

- Text overlap: **87.2%** (Jaccard, set-equality per `<text>` content)
- Text count delta: **-83** (-0.4% vs reference; effectively at parity)
- Shape counts: rect -460 (-20.9%), polygon -166 (-11.2%), path -181 (-5.1%)
- Within tolerance: 123/188 diagrams (65.4%)

## Closed Gaps

1. QEA `$LLB=...;LLT=...;LRB=...;LRT=...` parsing — only first segment
   carries `$`, the rest are `KEY=` after `;`. Fixed.
2. Connector label rendering at LLT/LRT box positions, with role + «property»
   + mult. Fixed.
3. Abstract class underscore — the underscore lives in the QEA class name
   itself (`_CityObject`), not added by EA at render time. Fixed.
4. Enumeration `«enumeration»` stereotype fallback. Fixed.
5. Connector-level stereotype label (e.g. «import» on Package connector).
   Fixed.
6. Attribute default value rendering (`name: type [mult] = default`). Fixed.
7. Enumeration literal visibility marker (`<text> </text>` empty slot).
   Fixed.
8. Multiplicity 1..1 → "1" rendering when paired with role name. Fixed.

## Open Gaps

### Text overlap (87.2% → target ~95%+)

1. **Auto-generated legend block** (~448 missing texts):
   - "凡例" (Legend title, 12pt bold #003060)
   - "GMLで定義されたクラス", "CityGMLで定義されたクラス",
     "i-URで定義されたクラス" (3 color-coded class titles)
   - "GMLに定義されたクラス", "CityGMLに定義されたクラス",
     "i-URに定義されたクラス" (alternative particle に instead of で)
   - EA auto-generates these when a diagram contains color-coded
     stereotype elements. Source data location TBD — likely tied to
     diagram-type or per-diagram MDGDgm flag.

2. **Ghost element discriminator** (TODO-D 20, deferred):
   - Some elements without explicit `font=` in their ObjectStyle get
     ghost rendering (7pt #595959, no attrs); others get full rendering.
   - Tested font_family presence → broke parity (-5000 texts).
   - Tested classifier.package_id match → broke parity (-1500 texts).
   - Real discriminator likely combines: ObjectStyle detail level +
     diagram context + classifier source package. Needs EA.exe
     disassembly reference.

3. **Missing class headers** (~150 instances):
   - Elements like `_AbstractGeometricAggregate`, `_CityObject`,
     `_Site`, `_Feature`, `_TransportationObject` appear in reference
     SVGs but not in t_diagramobjects for the diagram.
   - Cause: either EA renders implicit elements from connector
     endpoints, or the reference SVGs were generated from a different
     QEA version than what we have.

4. **`(from CityGML2.0)` qualifier** (9 instances):
   - EA shows a sub-line for elements imported from a specific
     package version.
   - Source: probably t_object.Package_ID joined with t_package
     version metadata.

### Shape counts

1. **rect -460**:
   - ~3 rects per diagram missing from legend block (container with
     rx=3 + 3 color swatch rects). 188 diagrams × ~3 = ~564 expected,
     close to actual -460 gap.
   - Need legend modeling first (depends on Text gap #1).

2. **polygon -166**:
   - Per-diagram marker counts differ — EA emits duplicate polygons
     at overlapping connector endpoints (e.g. 7 identical triangles
     at one position). Cause unknown.
   - Likely needs investigation of t_diagramlinks.Hidden vs visible
     flag and how EA consolidates markers.

3. **path -181**:
   - EA splits connector paths into individual segments per
     style group. We consolidate same-style paths into one `<g>`.
   - Some diagrams have 30+ path delta — needs path-per-connector
     vs grouped-path mode selection per diagram.

## Next Steps

1. Investigate auto-generated legend feature: how EA detects "this
   diagram needs a legend" and where the legend text/colors come from.
2. Find a reliable ghost-element discriminator (likely involves
   per-element display flags we haven't parsed yet).
3. Investigate duplicate-polygon emission for overlapping markers.
