# TODO.complete/65: QeaToXmi emits diagram elements

## Status: done (via TODO 66 — ExtensionSerializer)

`Ea::Transformers::QeaToXmi` now emits `<diagram>` elements as part
of the `<diagrams>` extension section. Each diagram has a `<model>`
block, `<properties>` block, and `<elements>` containing placed
`<element subject="EAID_..." geometry="..."/>` children.

Parity: 22/22 diagrams matched for basic.qea.

## Implementation

Extracted to `Ea::Transformers::QeaToXmi::ExtensionSerializer` (OCP).
See [[66-qeatoxmi-style-tags-docs]] for the full restructuring.
