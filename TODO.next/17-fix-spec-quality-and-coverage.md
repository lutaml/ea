# 17 - Fix Spec Quality: Eliminate Doubles, Add Missing Coverage

## Status: PARTIALLY DONE (remaining doubles don't cause failures)

## What's done this session
- `send` on private methods — 0 occurrences (eliminated)
- `instance_variable_get/set` — 0 occurrences (eliminated)
- `method_defined?` — 0 occurrences (eliminated)
- `double("Connector", class: ...)` in style_resolver_spec — replaced with real UML objects
- `double("Database")` in class_transformer_spec — replaced with real `build_test_database`
- `double("Database")` in package_transformer_spec — replaced with real `build_test_database`
- `double("Database")` in association_transformer_spec — replaced with real `build_test_database`
- `double("Element")` in base_renderer_spec — replaced with `Struct.new`
- `double("Connection")` removed from factory specs
- **Stdlib method shadowing audit on `BaseRepository`** — audited (2026-06-27):
  `find`, `count`, `any?`, `none?`, `group_by` deliberately shadow
  `Enumerable` with ActiveRecord-like signatures (PK lookup, conditions hash,
  attribute symbol). This is intentional API design, not a bug. `find` is
  O(1) via lazy primary-key index (`build_pk_index`); `find_by_key` and
  `where` remain O(n) — see [[16-repository-indexes]] for the decision to
  not optimize those.

## Remaining doubles (low priority — tests pass)
Some factory specs still use `double()` for auxiliary objects. These should be
replaced with real instances or Structs for maximum fidelity, but they don't
cause test failures.

## Coverage added
- `spec/ea/qea/standalone_api_spec.rb` (7 examples) — standalone API coverage
- All 1845 examples passing with 0 failures
- Full suite after this session's refactors: **1953 examples, 0 failures, 37 pending**

