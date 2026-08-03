# TODO-D 20: Split Labels emitter into MECE collaborators

## Problem

`Ea::Svg::EaEmitter::Labels` currently handles three distinct
responsibilities:

1. Connector midpoint stereotype labels (e.g. «import»).
2. End-label role + «property» + multiplicity rendering.
3. Geometry box parsing and position resolution.

These change for different reasons:

- Midpoint rendering changes when EA's connector stereotype
  conventions change.
- End-label rendering changes when role-name / multiplicity
  rules change.
- Box parsing changes when the QEA geometry format changes.

MECE violation: the three concerns overlap inside one class. OCP
violation: adding a new label kind (e.g. connector name above the
midpoint) requires editing Labels rather than registering a new
collaborator.

## Fix

Introduce a small LabelRenderer registry:

```
Ea::Svg::EaEmitter::Label
  ├─ EndLabel    (role + «property» + mult at LLT/LRT boxes)
  ├─ MidpointLabel (stereotype at path midpoint)
  └─ Registry    (dispatch by relationship kind / connector flag)
```

`Labels#texts_for` becomes:

```ruby
def texts_for(connector)
  points = waypoint_pairs(connector)
  return [] if points.size < 2

  Label::Registry.for(connector, model_index: model_index)
                 .flat_map { |r| r.texts(connector, points) }
end
```

Each renderer is independently testable. New label kinds are added
by registering, not by editing Labels (OCP).

## Acceptance

- Three discrete classes; each has its own spec.
- No behavior change (parity text overlap ≥ 87%).
- Existing labels spec still passes.
- New midpoint label spec covers the «import» path.
