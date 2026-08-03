# TODO.complete/60: Curate JSON export schema

## Status: done

`Ea::Export::Json::Generator` dumps `record.to_hash` raw, which
includes Lutaml::Model internals (e.g. `record_type` field is
added by us but other internals may leak).

## Plan

1. Define a per-collection projection: for each model class, list
   the fields to include in JSON output.
2. Walk collections, project each record through the curated schema.
3. Output `{ "collections": { "objects": [...], "packages": [...], ... } }`
   with a top-level structure (current output is flat).

## Acceptance

- Spec: JSON output has a stable schema documented in the spec.
- Spec: Lutaml::Model internals do not appear in output.
