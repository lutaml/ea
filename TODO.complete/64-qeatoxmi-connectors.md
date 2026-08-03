# TODO.complete/64: QeaToXmi emits connector elements

## Status: done (via TODO 66 — ExtensionSerializer)

`Ea::Transformers::QeaToXmi` now emits `<connector>` elements as part
of the `<connectors>` extension section. Each connector has full
source/target/end blocks with `<style>`, `<documentation/>`, `<tags/>`
each, plus connector-level body (properties, appearance, style).

Parity: 72/72 connectors matched for basic.qea.

## Implementation

Extracted to `Ea::Transformers::QeaToXmi::ExtensionSerializer` (OCP).
See [[66-qeatoxmi-style-tags-docs]] for the full restructuring.
