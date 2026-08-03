# TODO.complete/72: ExtensionSerializer OCP + naming fixes

## Status: done

Follow-on cleanup to the ExtensionSerializer introduced in TODO 66.

## Changes

1. **OCP**: `uml_type_for` was a `case/when` on `obj.object_type`.
   Refactored to `UML_TYPE_FOR` registry hash. Adding a new EA
   object type → UML type mapping = adding one hash entry, not
   editing a case/when branch.

2. **Naming**: `sType:` keyword argument renamed to `stype:` (Ruby
   snake_case convention). XML output still emits `sType="..."`
   (Sparx XMI attribute name).

3. **Cyclomatic complexity**: the `uml_type_for` case/when
   triggered Metrics/CyclomaticComplexity (8 branches). The registry
   hash eliminates the offense.

## Acceptance

- `bundle exec ea export xmi examples/qea/basic.qea` produces same
  output as before (style=508, tags=508, documentation=345).
- Parity spec passes.
