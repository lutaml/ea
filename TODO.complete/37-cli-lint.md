# TODO.complete/37: `ea lint` command

## Status: done

Model quality checks beyond structural validation:
- Naming convention violations (CamelCase classes, camelCase attrs)
- Missing stereotypes on packages marked ApplicationSchema
- Orphan elements (no package)
- Cyclic generalization chains
- Duplicate names within a package

## Plan

1. `Ea::Lint::Engine` — runs a registry of `LintRule` instances.
2. Each `LintRule` is a small class with `#check(model) → Array<Offense>`.
3. Register rules:
   - `NamingConventionRule`
   - `MissingStereotypeRule`
   - `OrphanElementRule`
   - `CyclicGeneralizationRule`
   - `DuplicateNameRule`
4. CLI: `ea lint FILE [--rule=name] [--severity=error|warning]`.

## OCP

- New rule = new class + register call. No engine changes.

## Acceptance

- `ea lint examples/qea/test.qea` reports at least one offense.
- Exit code 1 when errors found.
- JSON output via `--format json`.
