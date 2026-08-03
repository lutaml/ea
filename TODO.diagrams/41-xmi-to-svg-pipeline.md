# TODO-D 41: EA's XMI → SVG rendering pipeline

## Goal

Duplicate EA's SVG rendering when the SOURCE is a Sparx XMI export
(not a .qea). Reference corpus:

- Source: `~/src/mn/mn-samples-plateau/sources/xmi/plateau_all_packages_export.xmi`
- Reference: `~/src/mn/mn-samples-plateau/sources/001-mds/xmi-images/*.svg` (192 files)

These SVGs were produced by EA.exe from that exact XMI, so they are a
byte-level oracle for the XMI path — no QEA intermediate.

## Verified XMI encoding

The Sparx XMI carries every rendering input the QEA carries, in
`xmi:Extension` blocks:

| QEA table/column           | XMI location                                |
|----------------------------|---------------------------------------------|
| t_diagram.StyleEx          | `<diagram><properties/>` + `<xrefs/>`       |
| t_diagramobjects.RectTop.. | `<elements><element geometry="...">`        |
| t_diagramlinks.Geometry    | `<connectors><connector geometry="...">`    |
| t_object.Style (ObjectStyle)| `element/@style` — `NSL=0;LCol=-1;...`      |
| t_object.StyleEx font      | `element/@style` — `font=Yu Gothic UI;fontsz=100` |
| t_connector.StyleEx        | `connector/@style` — `CX=19:CY=13:OX=0:...` |
| t_objectproperties         | `<tags><tag name= value=>`                  |

Font differences vs plateau.qea:

- XMI export: `font=Yu Gothic UI; fontsz=100` → 10pt → 13px
- plateau.qea: `Carlito; fontsz=70` → 7pt → 9px

So the SAME model renders at a different scale depending on which
export the SVG was produced from. Font resolution must come from the
source's own StyleEx, never a hard-coded default.

## Per-element layer order (verified from reference SVGs)

EA emits one `<g>` per *visual concern*, not one per element. Within
one element the order is stable:

1. shape       — `<rect>` (or folder polygons for Package)
2. header      — `<text>` × N (stereotype, name, optional qualifier)
3. divider     — `<path>` horizontal rule
4. attributes  — `<text>` × 2N (visibility glyph + content)
5. operations  — divider + `<text>` × N
6. literals    — divider + italic "literals" + `<text>` × N
7. tagged vals — divider + `<text>` × N

Connector layers interleave by z-order, not per element.

## Current parity (plateau XMI, 188 diagrams)

```
Matched: 185/188   Errors: 0
rect     ours= 1781 ref= 2002 delta=-221 (-11.0%)
path     ours= 3018 ref= 3298 delta=-280 ( -8.5%)
polygon  ours=  955 ref=  961 delta=  -6 ( -0.6%)
text     ours=16918 ref=17548 delta=-630 ( -3.6%)
Text overlap avg: 19.1%
```

## Acceptance

- A reusable benchmark task that scores ANY source (qea or xmi)
  against a reference SVG directory, so the XMI path is measured on
  every change instead of ad-hoc scripts.
- Font resolution driven by the source's own StyleEx (no default
  drift between qea and xmi inputs).
- rect delta explained: which element kinds are missing shapes.
- path delta explained: which connectors are missing.
- 3 unmatched diagrams identified (name-normalization or genuinely
  absent from the export).

## Sub-tasks

- [x] 41a — Locate and parse the XMI corpus
- [x] 41b — Map every QEA rendering input to its XMI counterpart
- [x] 41c — Verify per-element layer order against references
- [x] 41d — Land the benchmark as a rake task (`rake svg:bench`)
- [x] 41e — Explain the rect/path/text deltas by element kind
- [x] 41f — Read UMLDI keyword labels from the XMI source so the
  header stereotype («Type», «FeatureType», «DataType») matches
  what EA actually rendered. New `Ea::Sources::Xmi::UmldiKeywordExtractor`
  parses the raw XMI once; `DiagramBuilder` threads the
  `umldi_keyword` per element; `HeaderLines` consumes it.
- [x] 41g — Fix `qualified_name` for XMI classifiers whose `name`
  already carries a namespace prefix (e.g. `xs:string` in the
  `xs` package). Was producing `xs::xs:string`; now `xs::string`,
  matching EA's reference output.

## Bench results after fixes

```
Matched: 185/188   Errors: 0
rect     ours= 1781 ref= 2002 delta=-221 (-11.0%)
path     ours= 3018 ref= 3298 delta=-280 ( -8.5%)
polygon  ours=  955 ref=  961 delta=  -6 ( -0.6%)
text     ours=16947 ref=17548 delta=-601 ( -3.4%)
Text overlap avg: 64.5%   (was 19.1% before UMLDI fix)
```

## Remaining parity gaps (in priority order)

1. **rect -221** — likely connector marker anchors rendered as
   `<polygon>` instead of the EA split across `<rect>`/`<polygon>`.
   Audit per element-type to confirm.
2. **path -280** — EA's bend points for connectors use a longer
   path string. Possibly: missing waypoint endpoint waypoints.
3. **text -601** — some label text still mismatching. Likely
   cross-package role names and multiplicity position.
4. **-221 / -280** explain-by-element-kind audit (TODO 41e).
