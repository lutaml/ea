# TODO.complete/66: QeaToXmi emits style / tags / documentation

## Status: open

EA's reference XMI contains hundreds of `<style>`, `<tags>`, and
`<documentation>` elements per diagram. Ours emits zero. Per the
parity spec: 0/663 styles, 0/478 tags, 0/357 documentation entries.

## Plan

1. Walk `t_diagramlinks` to find connector+element style strings.
2. Emit `<style>` children of `<connector>` / `<element>` with the
   stored style XML verbatim.
3. Walk `t_taggedvalue` for tagged values; emit as `<tags>` children
   with `<tag>` items.
4. Walk `t_objectnotes` for documentation; emit as `<documentation>`
   children of the owning element.

## Acceptance

- Output contains `<style>`, `<tags>`, `<documentation>` elements.
- Parity threshold raised from 50% to 75%.

## OCP

Each sub-element type (style/tags/documentation) is a private
emitter method dispatched by collection. New element types = new
case branch.
