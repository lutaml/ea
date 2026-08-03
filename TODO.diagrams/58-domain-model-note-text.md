# TODO-D 58: Domain Model note text + missing multiplicity

## Status: open (blocks 1 basic.qea diagram)

Domain Model is at shape_delta_total=0 (sum-zero parity) but has
text_delta=-7. Two missing items:

### A. Wrapped note text (-6)

EA wraps long note text across multiple `<text>` lines. For the
Domain Model Concepts, the note `"Detailed notes that describe the
concept."` is wrapped onto two lines per element:

  <text x="45" y="95">[Detailed notes that describe the </text>
  <text x="45" y="109">concept.]</text>

The leading `[` and trailing `]` are EA's convention for marking
the note body (not part of the actual note content). Line-wrap
width is determined by the element bounds width minus padding
(~125px usable for a 167px-wide box at font size 7pt).

Currently we don't render note text in element bodies at all. The
note text comes from `t_object.Note`.

### B. Missing target multiplicity (-1)

One Aggregation connector (`Relationship Two`) has source mult
`0..*` (rendered at top) and target mult `1..1` (should render
near Concept A's top edge but doesn't). The target endpoint lands
inside the element box and our EndLabel skips the label.

## Implementation plan

### For (A) — wrapped note text

- `Ea::Model::Classifier` already has `annotations` — re-use for
  the documentation note OR add `note :string` as a separate field
  (EA's `t_object.Note` is distinct from `t_objectproperties` tagged
  values).
- `Ea::Sources::Qea::ClassifierBuilder#note_for` reads `object.note`.
- New `Compartment::NoteText` (different from `Compartment::NoteBody`
  which handles Note elements):
  - Splits the note text into lines based on a width estimate
  - Wraps with `[` ... `]`
  - Renders one `<text>` per line below the header divider
- Discriminator: render when `classifier.note` is non-empty AND
  the element has no attribute compartment (the note replaces
  attributes in this style).

### For (B) — multiplicity inside element

- `Ea::Svg::EaEmitter::Label::EndLabel`: relax the
  "skip when inside element" rule for multiplicity labels — they
  should render even when the anchor is inside an element box
  (just offset outward).

## Verification

- basic.qea "Domain Model": text_delta -7 → 0.
- basic.qea: 16/22 → 17/22 strict-perfect.

## Why deferred

Note wrapping needs a width-estimation helper (font size × char
count × width factor) and a `Compartment::NoteText` module. The
multiplicity fix requires relaxing EndLabel's collision rule which
could regress other diagrams.
