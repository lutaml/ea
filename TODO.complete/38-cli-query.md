# TODO.complete/38: `ea query` command

## Status: done

Filter/search DSL for ad-hoc exploration. Currently you can list
everything but can't say "find all classes named X" or "classes
with stereotype FeatureType in package Y".

## Plan

1. `Ea::Query::Dsl` — small chainable builder:
   ```ruby
   Ea::Query.new(model).classes.in_package("core").with_stereotype("FeatureType").call
   ```
2. CLI: `ea query FILE --type=class --stereotype=FeatureType`.
3. Output formats: table (default), json, yaml.

## OCP

- New predicate = new method on the DSL chain. Existing methods
  unchanged.

## Acceptance

- Spec: query returns expected subset for each predicate.
- CLI: `ea query examples/qea/test.qea --type=class` lists classes.
