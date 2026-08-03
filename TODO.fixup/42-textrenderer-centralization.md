# 42 - TextRenderer Centralization (DRY)

## Status: DONE (2026-07-25)

Merged with TODO 33. Single TextRenderer replaces 6 duplicated
build_text helpers across:
- HeaderRenderer, AttributeRenderer, OperationRenderer,
  EnumerationLiteralRenderer, Labels, DiagramFrame.

See TODO.fixup/33 for details.
