# TODO.complete/39: `ea info` command

## Status: open

Show details of a single element by name or GUID. Useful for
debugging and exploration without firing up a GUI.

## Plan

1. `ea info NAME FILE` — find element by name, print structured info:
   - Identity (name, type, GUID, package path)
   - Attributes (name, type, visibility)
   - Operations (name, params, return type)
   - Stereotypes applied
   - Tagged values
   - Constraints (OCL)
   - Generalizations (parents and children)
2. Output: human-readable by default, JSON via `--format json`.

## Acceptance

- Spec: `ea info "FeatureType1" examples/qea/test.qea` shows class details.
- Exit 1 when element not found.
