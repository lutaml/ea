# 80 - Tagged value and stereotype visibility rules

## Status: TODO

## Context

Only 2 of 220 reference SVGs in `examples/exports/` render a
"tags" header compartment, even though most plateau elements have
`Tag=1` in their per-element style and most classifiers have
tagged values from stereotype applications.

Likewise, the simple.xmi "Package A.1.1" reference shows
`«DataType»` for AcmeUmlClass, but the plateau Tunnel reference
does NOT show `«DataType»` for classifiers that also have
`stereotype="DataType"`.

## What needs to change

1. **Tagged value visibility rule**: Determine when EA actually
   renders the tags compartment. Likely factors:
   - Stereotype source (profile-applied vs user-defined tagged values)
   - Element style `Tag=` flag semantics (currently parsed but unused)
   - Diagram Style1 `ShowTags=` flag interaction

2. **Stereotype label visibility rule**: Determine when EA renders
   the `«Stereotype»` label. Hypotheses to verify:
   - Ref SVGs show stereotypes only when the classifier is NOT
     a "primitive" type or abstract base
   - Show stereotypes only when they come from a non-default profile
   - Show only when `HideElemStereo=0` AND the element is in a
     specific diagram type

## Acceptance

- Visibility rules documented with concrete EA behavior citations
- Implementation gates tagged value + stereotype rendering
- Sample parity improves from 88 percent toward 95 percent+
