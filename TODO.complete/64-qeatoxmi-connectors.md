# TODO.complete/64: QeaToXmi emits connector elements

## Status: open

`Ea::Transformers::QeaToXmi` emits associations as `<memberEnd>` +
`<ownedEnd>` on the owning class, but does NOT emit EA's
`<connector>` elements. Per the parity regression spec, that's the
#1 missing category (73/73 in basic.qea, 73/80 in plateau).

## Plan

1. After serializing the model root + classes, walk `t_connector`
   for associations/aggregations/compositions.
2. For each connector, locate the corresponding `t_diagramlinks` row
   to retrieve geometry (SX/SY/EX/EY/EDGE) and visual style
   (lineStyle/lineColor).
3. Emit `<connector>` element with geometry in `<style>` sub-element.

## Acceptance

- `ea export xmi` output for basic.qea now contains
  `<connector>` elements (was 0/73).
- `spec/ea/validation/xmi_parity_spec.rb` packagedElement threshold
  raised from 5% to 25% (connectors represent ~25% of EA's output).

## OCP

Each connector type (Association/Aggregation/Composition) gets a
private serializer method dispatched by `connector_type`. New
connector types = new case branch; no other code changes.
