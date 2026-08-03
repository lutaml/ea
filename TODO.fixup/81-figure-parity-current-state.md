# 81 - Figure parity current state and roadmap

## Status: LIVING DOCUMENT (2026-07-26)

## Where we are

- **193/220 sample diagrams (88%)** render within shape-count
  tolerance of EA's reference SVGs.
- **1596 specs, all passing.**
- **Major code cleanup**: removed 695 legacy spec examples and
  ~3000 lines of dead production code (Transformations engine,
  Diagram legacy renderers).

## What's working

- Theme system auto-detects Theme=:119 (Carlito 7pt) from XMI
  style2 attribute.
- DisplayConfig correctly reads HideAtts/HideOps (Style1) and
  SuppressFOC/AttPub (StyleEx) as separate concerns.
- Packages render as polygon body+tab (matching EA folder shape).
- Notes render as folded-corner rect with body text.
- Tagged values render when classifier has them.
- Connector Path= coordinates treated as absolute (matching EA
  reference SVG geometry).
- Per-element Tag flag, EAPK↔EAID alias for package lookups,
  frame border+tab always rendered.

## What's still off (and where the 12% gap lives)

### 1. Stereotype label visibility (TODO 80)
We render `«DataType»` for every classifier with a stereotype,
but reference SVGs only render some. The rule appears to be
profile-specific (GML stereotypes shown, others hidden) but not
yet characterized.

### 2. Tagged value visibility (TODO 80)
Only 2/220 reference diagrams show the "tags" compartment, but
we render it on every classifier with tagged values. Likely
tied to the same stereotype visibility rule.

### 3. Canvas size non-parity (TODO 77)
Our canvas is ~40px narrower and ~26px shorter than reference
due to non-uniform EA frame margins (left=35, right=50, top=60,
bottom=36). Functional but visually offset.

### 4. Visibility toggle icons (TODO 75 — wontfix)
3-4 small 17×17 colored rects appear on a few diagrams as
manually-authored Note element legend content. Not a generic
feature; closed as wontfix.

## Next high-value investigations

1. **Compare ref SVGs element-by-element** to characterize the
   stereotype visibility rule. Likely factors: element style
   `Tag=`, HideElemStereo, stereotype FQName prefix.

2. **Parse t_diagram.cx/cy** (canvas dimensions stored in QEA,
   lost in XMI export) for exact canvas sizing. XMI uses DocSize
   which is paper-size, not pixel-canvas.

3. **Wire QEA loader to skip XMI** — parsing QEA directly gives
   StyleEx, exact element positions, and tagged value scopes
   that the XMI export loses.
