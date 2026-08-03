# TODO-D 51: «property» OY-gap rule + remaining examples gaps

## Completed

### «property» label discriminator (DONE)

`EndLabel#property_label?` now actually inspects the LLT/LLB OY
gap and returns false when below 15px. Previously it always
returned true, causing 4-8 spurious «property» texts per diagram
in basic.qea.

After fix:
- basic.qea 'Basic Class Diagram with Operations' → 100% parity
- basic.qea text overlap: 84.0% (high — most matching text correct)
- plateau text overlap unchanged at 64.5%
- plateau text count delta: -601 → -627 (correctly removes the
  spurious «property» labels that ref doesn't have)

## Remaining example gaps (still open)

### Visibility icons (Test Model + Package Imports)

EA renders a complex "folded page" icon for each attribute row in
some diagram styles:
- 1 outer rect (11x14, pale yellow fill, blue stroke)
- 1 inner rect (11x4 at top, white fill, blue stroke)
- 1 horizontal divider path (midline)
- 3-4 short "text line" paths inside (4px wide each)

That's 5-6 elements per attribute row. Discriminator likely the
`ShowIcons=1` flag in diagram Style1.

### Object instance rendering (Objects as Instances of Classes)

EA renders `Object 01 / roleOne: Class A` (instance name + role +
classifier) and `attribute = value` slots. Requires a new
InstanceSpecification model + renderer.

### Domain Model connector routing

Ref uses cubic bezier (`C`) for connector paths in tree mode;
we use linear `L` segments. The visual is similar but path
geometry differs. EA also emits more sub-paths per connector
in some layouts.

## Verification

`rake svg:examples` shows current state. 15/27 diagrams at 100%.
