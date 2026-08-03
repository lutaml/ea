# TODO.complete/65: QeaToXmi emits diagram elements

## Status: open

`Ea::Transformers::QeaToXmi` does not emit EA's `<diagram>` elements
at all. The parity spec confirms 0/23 in basic.qea, 0/2 in test.qea.

## Plan

1. Walk `t_diagram` for every diagram.
2. For each diagram, walk `t_diagramlinks` to find placed
   elements + connectors; emit them as `<element>` children of
   `<diagram>`.
3. Each element child references its `xmi:idref` to the model
   class.
4. Connector children emit as `<connector>` with geometry (see
   TODO 64).

## Acceptance

- `ea export xmi` output for basic.qea now contains
  `<diagram>` elements (was 0/23).
- Parity threshold raised from 25% to 50%.

## OCP

Diagrams emit via a new private method `emit_diagrams(model)`
called after the model class tree. Adding new diagram metadata
(swimlane info, etc.) = new private method, no other changes.
