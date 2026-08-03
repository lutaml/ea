# TODO-D 46: User-drawn legend swatches (colored marker rects)

## Symptom

Some diagrams include manually-drawn legend boxes — small colored
`<rect>` elements (typically 17×17) accompanied by text labels,
grouped inside a larger "legend" container rect.

Reference SVG for `EAID_5A43833E_680B_4a90_8931_0C902304E029` has:

```
<rect x="647" y="751" width="17" height="17" fill="#CCFFCC" .../>
<text>GMLに定義されたクラス</text>
<rect x="647" y="770" width="17" height="17" fill="#FFFFCC" .../>
<text>CityGMLに定義されたクラス</text>
<rect x="647" y="789" width="17" height="17" fill="#FFCCFF" .../>
```

These are NOT modeled classifiers — they're user-drawn shapes
inside a "diagram note" or "text" element.

## Source

EA encodes these as nested `<element>` rows inside a parent
`<element>` in the extension block, OR as separate `<element>`
rows whose `subject` references a "Note" or "Text" classifier with
custom geometry/style.

In the plateau XMI, these specific swatches appear to be embedded
in a Klass with `name=nil` that serves as the legend frame. The
swatches themselves are not present as separate element rows.

## Acceptance

- Investigate whether the XMI carries these as nested elements,
  tagged values, or Note element children.
- If unrecoverable from XMI, document as "out of scope — user
  decoration not encoded in the model" and exclude from parity
  measurement.

## Bench impact

About 50-100 rects across the plateau set. Cannot be fully closed
without explicit source data.
