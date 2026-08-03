# TODO-D 73: Plateau polygon under-render (-4)

## Status: partially investigated (2026-08-02)

Across 188 plateau diagrams, we render 4 fewer `<polygon>` elements
than EA's reference SVG. Per-diagram deltas:

  - Appearance (BC1F7E00, C31C1314): -2 each
  - CityGMLCore (88D0CB44): -1
  - 都市計画決定情報の概要 (8FD488EF): -1
  - 立体的な範囲、区域界、品質属性 (1321F39B): -1
  - 都市施設 (C96CBC24): -1
  - 3D都市モデル応用スキーマと他のスキーマとの関係 (DFBB1072): +3
  - udx (6481E2CC): +1

## Investigation update (2026-08-02)

For 都市施設 / 都市計画決定情報 / 立体的な範囲: each missing
polygon is a small 4-point DIAMOND inside an element body.

Example (都市施設):
  `<polygon points="323 401 328 411 333 401 328 391" ...>`
  Inside a `<g>` with fill="#FAF1EC" stroke="#69738C"

These colors (#FAF1EC, #69738C) are NOT standard aggregation
diamond colors (#FFFFFF fill, #000000 stroke). They appear to be
**stereotype decorator icons** — small symbolic icons EA renders
inside element bodies when a stereotype provides a custom icon.

## Follow-up investigation (2026-08-02)

Found EA installation at:
  ~/Library/Application Support/CrossOver/Bottles/
    Enterprise Architect 16.x/drive_c/Program Files/Sparx Systems/EA/

Located stereotype-related files:
  - Config/GML/GMLStereotypes.xml — only stereotype ALIASES, no icons
  - MDGTechnologies/*.xml — many MDG files, none reference icons
  - TemplateResources161.dll — likely contains compiled icon resources
  - t_stereotypes table — empty Metafile BLOBs for FeatureType

Found element-style flag `HideIcon=0` on FeatureType elements on
都市施設 — confirmed EA DOES intend to show an icon.

## Discriminator puzzle

On 都市施設, ALL 21 placed FeatureType elements have HideIcon=0.
But ref renders the diamond icon for only 1 of them
(CollectiveFacilitiesForReconstruction — the largest element).

The discriminator is NOT:
- HideIcon flag (all elements have it = 0)
- Stereotype (all are FeatureType)
- Element size (icon position is element-relative)

Hypotheses for the actual discriminator:
1. The element is "selected" or "active" in the source QEA
2. The element is the diagram's "subject" (a per-diagram flag)
3. The icon is part of a legend/key, not per-element

## Implementation needed

To close this gap requires either:
1. Reverse-engineering EA's stereotype decorator icon logic
2. Parsing the EMF BLOB from t_image (1 image, 69KB)
3. Extracting icon resources from EA.exe / TemplateResources161.dll

Even then, the discriminator for WHICH elements get icons is
unclear from available data.
