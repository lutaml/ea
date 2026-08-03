# TODO-D 61: Legend block rendering

## Status: completed

The plateau QEA's `t_object` rows with `Object_Type='Text'` and
`StyleEx` carrying `LegendOpts=` are auto-generated legend blocks.
EA renders each as a 4-rect + 4-text cluster (container + 3 colored
icons + title + 3 labels), with the legend configuration parsed
from a sibling `t_xref` row keyed off the same GUID.

## Implementation

- `Ea::Model::Legend` and `Ea::Model::LegendItem` — new models
  carrying the legend title, colors (BGR-packed), and per-item
  background colors. Default colors pulled from plateau SVG refs.
- `Ea::Model::Note` gains an optional `legend` attribute. Text
  elements with `LegendOpts=` in StyleEx parse the legend payload
  at load time; other Notes stay unencumbered.
- `Ea::Sources::Qea::LegendBuilder` parses the `@PROP=...@ENDPROP;`
  blobs in `t_xref.Description` for a given Text element GUID.
- `Ea::Svg::EaEmitter::Element::LegendRenderer` emits the container
  rect, icon rects, title text, and item labels. BGR colors decode
  via the existing `Element::BColDecoder`.
- `Compartment::Shape` dispatches to `LegendRenderer` when the
  element carries a legend payload; `Compartment::NoteBody` skips
  rendering (legend replaces note body).

## Related fix: marker dedup removed

Reference inspection showed EA does NOT dedup polygon markers even
when N connectors share the same anchor — the Bridge diagram emits
9 distinct triangle polygons at one parent anchor. Removed the
`Markers::Entry#generalization_tree_routed?` dedup logic; EA emits
one marker per connector, period.

## Related fix: spec pollution

`spec/ea/svg/qea_regression_spec.rb` and
`spec/ea/svg/visual_regression_spec.rb` both defined top-level
constants named `REF_DIR` inside `RSpec.describe` blocks. Ruby
resolves these to top-level constants — the spec loaded second
won, silently pointing the other spec at the wrong reference SVG
directory. Renamed to `QEA_REF_DIR` and `VISUAL_REF_DIR`.

## Results (plateau QEA)

| Metric  | Before | After  | Change |
|---------|--------|--------|--------|
| Matched | 130/188| 137/188| +7     |
| rect    | -460   | +4     | +464   |
| path    | -92    | -92    | —      |
| polygon | +27    | +25    | -2     |
| text    | -519   | -55    | +464   |

basic.qea and test.qea remain at 22/22 and 2/2 respectively.
