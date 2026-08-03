# TODO.complete/43: JSON Schema export

## Status: open

XSD is one XML schema format. JSON Schema is the JSON equivalent
and equally useful for downstream tooling (API validation, form
generation).

## Plan

1. `Ea::Export::JsonSchema::Generator` — walks classes, emits a
   `{ "$schema": "https://json-schema.org/draft/2020-12/schema",
   "type": "object", "properties": { ... } }` document.
2. CLI: `ea export json-schema FILE -o schema.json`.
3. Reuse the XSD ClassMapping for type translation.

## Acceptance

- Spec: output parses as valid JSON Schema.
- Spec: each UML class becomes a `$defs` entry.
