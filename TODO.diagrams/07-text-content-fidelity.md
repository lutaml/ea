# TODO-D 07 - Full text content fidelity

## Status: PARTIAL (62% overlap) (2026-07-26)

## Current state

Text overlap (Jaccard index of text content sets between our SVG
and reference SVG):

- Average across 185 plateau diagrams: **62%**
- Best diagrams: ~95%
- Worst diagrams: ~20%

## What's working

- Classifier names and stereotypes render correctly when the
  element is placed on the diagram.
- Attribute text matches when the element has Tag=0 (no tagged
  values compartment).
- Visibility prefixes ("+ ", "- ") match.
- Multiplicity brackets match.

## What's still off

### 1. Tagged value visibility (mostly fixed, edge cases remain)
Reference SVGs don't render the "tags" header compartment except
on 2 diagrams. Our Tag-flag gating brought text overlap from 41%
to 62%. Remaining misses are likely from elements where the
`Tag=1` flag is set but the reference still doesn't render tags
— possibly tied to stereotype source (profile-applied vs
user-defined tagged values).

### 2. Qualified name vs simple name
Reference uses qualified names like
`uro::TrafficVolumeAttribute`. Our output sometimes uses the
short name only. The qualified_name attribute is set on the
Classifier model, but the renderer doesn't always pick it up
correctly when the element is placed on a sub-package diagram.

### 3. Attribute ordering
Within a classifier's attribute compartment, EA sorts attributes
by some criteria (possibly visibility then alphabetical). Our
ordering follows the XMI's `ownedAttribute` order, which may
differ.

### 4. Attribute visibility color
Reference uses different fill colors for public/protected/private
attributes (`#66413F` for some, `#595959` for others). Our
renderer uses a single text color from the theme.

## Path to 100% text overlap

1. Characterize the tagged value visibility rule by examining
   which elements with `Tag=1` still don't render tags in
   reference (estimated 5-10 diagrams).

2. Always use `classifier.qualified_name` for the header label
   (currently mixed).

3. Sort attributes by visibility prefix, then alphabetical.

4. Apply theme.color_for_attribute_visibility for attribute text.

Each of these is a separate fix. None require architectural
changes.
