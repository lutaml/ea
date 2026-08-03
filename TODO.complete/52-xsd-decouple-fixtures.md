# TODO.complete/52: Decouple XSD Generator from fixture paths

## Status: open

`Ea::Export::Xsd::Generator` hardcodes:
    DEFAULT_MAPPING_PATH = "spec/fixtures/mdg/ea_config/gml/GMLClassMapping.xml"

Lib code should never reference `spec/` paths. The CLI layer should
load fixtures (it knows about the dev environment) and pass the
parsed data to the Generator.

## Plan

1. Generator's `initialize` defaults to empty `ClassMapping.new` /
   `NamespaceRegistry.new` (no file IO).
2. CLI `ea export xsd` loads fixtures when present and passes them
   to the Generator.
3. Generator stays pure: data in, XSD out.

## Acceptance

- `grep -n "spec/fixtures" lib/ea/export/` returns 0 hits.
- `ea export xsd` still produces valid XSD when run from repo root.
