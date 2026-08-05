# TODO.complete/86: frozen_string_literal sweep + Lint/Query specs

## Status: done

## 1. frozen_string_literal: wrong-variant sweep

Found 13 files with the **non-functional** `# frozen_string: true`
variant (Ruby only recognizes `# frozen_string_literal: true`).
These files' string literals were NOT frozen — silent correctness
gap.

Files fixed (wrong variant → correct):
- `lib/ea/svg/ea_emitter/marker/package_import.rb`
- `lib/ea/mdg/xml/*.rb` (11 files)
- `lib/ea/export/plantuml/generator.rb`

Also removed duplicate frozen comments from 8 files where my TODO
85 fix prepended the correct variant without removing the old wrong
one:
- `lib/ea/mdg.rb`, `mdg/document.rb`, `mdg/loader.rb`, `mdg/xml.rb`
- `lib/ea/model/ghost_label.rb`
- `lib/ea/svg/ea_emitter/ghost_labels.rb`, `background.rb`
- `lib/ea/cli/command/render.rb`
- `lib/ea/validation.rb`

All 421 lib files now have exactly one `# frozen_string_literal: true`
at line 1.

## 2. Lint subsystem specs (0 → 13 examples)

`spec/ea/lint/lint_spec.rb` — covers:
- `Offense#error?` / `#warning?` severity predicates
- `LintRule.name` CamelCase → snake_case conversion
- `LintRule.severity` default + override
- `LintRule#check` NotImplementedError
- `LintRule#offense` factory (tested through subclass, not `send`)
- `Engine#run` collects from all rules
- `Engine::DEFAULT_RULES` loads 5 built-in rules

## 3. Query subsystem specs (0 → 11 examples)

`spec/ea/query/builder_spec.rb` — covers:
- `#classes`, `#interfaces`, `#packages` collection switching
- `#with_type` filtering
- `#in_package` by name
- `#named` exact match
- `#name_contains` case-insensitive substring
- Chaining + immutability (each method returns new Builder)
- Enumerable support via `#each`

## Result

- 49 new examples across Lint + Query + Validation subsystems.
- All lib files have correct `frozen_string_literal: true`.
- No banned patterns in new specs (no `double`, no `send` to private).
