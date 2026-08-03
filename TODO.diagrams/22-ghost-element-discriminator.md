# TODO-D 22: Ghost element discriminator

## Problem

EA renders some elements as "ghosts": smaller font (7pt), gray
text (#595959), no attribute/operation/tag compartments. The
discriminator is unclear.

## Empirical Observations

| Diagram            | Element                    | ObjectStyle                                          | Rendered as |
|--------------------|----------------------------|------------------------------------------------------|-------------|
| 位置図C0301        | _UrbanFunction             | NSL=0;LCol=-1;...font=Yu Gothic UI;...               | Full        |
| 位置図C0301        | MultiSurface               | NSL=0;BFol=-1;...fontsz=0;bold=0;... (no font=)      | Ghost       |
| CityGMLCore        | _Feature                   | NSL=0;BCol=-1;BFol=-1;LCol=-1;LWth=-1;fontsz=0;...   | Ghost       |
| urf_4              | _UrbanFunction             | NSL=0;BFol=-1;LCol=-1;fontsz=0;bold=0;... (no font=) | **Full**    |
| 都市計画決定情報   | _UrbanFunction             | NSL=0;LCol=-1;bold=0;... (no font=)                  | Ghost       |

The presence or absence of `font=` is **not** the discriminator
(urf_4 elements lack `font=` but render full attributes).

`BCol` value is **not** the discriminator (urf_4 has explicit
BCol=16777215; MultiSurface in 位置図C0301 has BCol=13434828).

Classifier `package_id` vs diagram `package_id` is **not** the
discriminator (urf_4 cross-package elements get full attrs;
CityGMLCore cross-package elements get ghost).

## Hypothesis To Test

1. **Diagram-level "is reference" flag**: maybe EA marks diagrams
   that only show snapshots of an external model. The discriminator
   could be `t_diagram.SPT=1` (already 1 in all observed diagrams)
   combined with another flag.

2. **Element-level "Link" semantics**: maybe elements placed as
   "links" rather than embedded get ghost styling. The QEA may
   encode this in t_diagramlinks.Path or t_object.Documentation
   style flags we haven't parsed.

3. **t_objectstatistics or t_objectproperties**: an explicit "ghost
   mode" tagged value.

## Status

Deferred. Without EA.exe disassembly or empirical testing inside
the EA GUI, the rule cannot be confidently derived.

## Acceptance (when picked up)

- Open the QEA in EA GUI, toggle the "Link" vs "Embed" property
  on an element, observe the rendered SVG, and identify the QEA
  field that changes.
- Implement a `ghost?` predicate on `Ea::Model::DiagramElement`
  using the discovered field.
- Wire through `Elements` emitter to apply ghost styling.
- Specs cover both ghost and full paths.
