# 44 - Theme-Aware TextRenderer

## Status: ANALYZED (2026-07-26, closed)

## Decision

TextRenderer already accepts per-call fill/weight/size_unit
overrides. Callers (HeaderRenderer, AttributeRenderer, etc.)
can pass theme-derived values explicitly. Adding theme
awareness inside TextRenderer would duplicate the FontResolver
logic — better to keep TextRenderer stateless.

Theme values flow through FontResolver which is now theme-aware
(fixup 45). HeaderRenderer etc. can consult FontResolver for
weight/size_unit/fill and pass to TextRenderer.

Closing — current design is correct MECE separation.
