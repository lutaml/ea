# TODO-D 45: Phantom parent class boxes (generalization tree)

## Symptom

Some diagrams render extra `<rect>`+`<text>` for a classifier that
is NOT placed on the diagram via `t_diagramobjects` (or XMI
`<elements>` block), but IS referenced as a generalization parent
by a connector on the diagram.

Reference SVG for `EAID_5A43833E_680B_4a90_8931_0C902304E029` has:

```
<rect x="161" y="161" width="179" height="80" .../>
<text>_AbstractGeometricAggregate</text>
```

The classifier `_AbstractGeometricAggregate` is the general parent
of one of the placed children, but is NOT placed itself. EA renders
a phantom box at the parent end of the generalization connector.

## Discriminator (hypothesis)

When a connector's `EOID` references a `DUID` that is NOT in the
placed-elements index, EA renders a minimal phantom box at the
connector's endpoint coordinate. The phantom box shows the parent
classifier's name and stereotype but no attributes/operations.

## Acceptance

- Detect connectors whose endpoint DUID has no matching placed
  element.
- Render a phantom box at the connector's endpoint with the
  referenced classifier's header.
- Bench rect delta improves by N where N is the count of phantom
  parents across the plateau reference set.

## Related

- TODO-D 26 (phantom class headers from connector endpoints) —
  same root cause, separate TODO for tracking.
