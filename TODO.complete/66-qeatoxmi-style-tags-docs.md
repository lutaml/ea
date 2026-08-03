# TODO.complete/66: QeaToXmi emits style / tags / documentation

## Status: done

EA's reference XMI contains hundreds of `<style>`, `<tags>`, and
`<documentation>` elements per diagram. Previously ours emitted zero.

## Outcome

Extracted extension serialization into `ExtensionSerializer` (OCP:
new element types = new method, no existing code change). Emits the
proper Sparx XMI structure:

- `<elements>` — one `<element>` per package/classifier, each with
  `<model>`, `<properties documentation="...">`, `<style>`, `<tags>`,
  and (for classifiers) `<attributes>` and `<operations>` sub-blocks.
- `<connectors>` — full source/target/end blocks with `<style>`,
  `<documentation/>`, `<tags/>` each, plus connector-level body.
- `<diagrams>` — placed `<element>` children with geometry.

Parity counts (basic.qea):

| type         | before | after | ref |
|--------------|--------|-------|-----|
| style        |      0 |   508 | 478 |
| tags         |      0 |   508 | 478 |
| documentation|      0 |   345 | 357 |

## Notes

- Removed banned `respond_to?` patterns from the old code.
- The old top-level `<tags>` and `<documentation>` sections were
  structurally wrong — Sparx nests these inside per-element blocks.
- `serialize(with_extensions: false)` (used by `ea convert`) skips
  this entirely for round-trip safety.
