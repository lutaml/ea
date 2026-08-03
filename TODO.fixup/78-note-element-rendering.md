# 78 - Note element rendering

## Status: COMPLETE (2026-07-26)

## What changed

- New `Ea::Model::Note` class (id, name, body, note_type)
- New `NoteBuilder` extracts Notes from `<xmi:Extension>/<elements>`
  via `ext_element.type == "uml:Note"`. The note body comes from
  `<properties documentation="..."/>`.
- `Document` gains a `notes` collection; `index_by_id` includes
  them so diagram element `subject=EAID_...` refs resolve.
- New `Element::NoteShapeRenderer` emits:
  - Folded-corner polygon (top-right corner cut)
  - Diagonal fold line marking the dog-ear
  - Body text with naive char-count-based word wrap
- `Elements#render_shape` dispatches to `NoteShapeRenderer` when
  the model element `is_a?(Ea::Model::Note)`.

## Acceptance

- Plateau document parses 27 Notes (was 0 before).
- 4 diagrams that place Notes on the canvas now render them.
- All 1596 specs pass.

## Limitations

Text wrapping uses character count, not GDI text metrics. EA uses
the latter for accurate wrap points; matching it would require
platform-specific font metric tables.
