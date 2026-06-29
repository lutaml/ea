# 09 - Fix ea gemspec: optional lutaml-uml, missing lutaml-model/lutaml-path

## Status: DONE (2026-06-29)

## Problem
`ea.gemspec` had two dependency-declaration bugs:

1. **`lutaml-uml` was declared as a hard runtime dependency**
   (`spec.add_dependency "lutaml-uml"`) even though the gem is
   documented as standalone with an OPTIONAL lutaml-uml bridge.
   `lib/ea/qea.rb#require_uml!` already lazy-requires `lutaml/uml`
   inside the method body with a clear `LoadError` rescue. The hard
   declaration defeated the optional-bridge design: `gem install ea`
   pulled in `lutaml-uml` (and its dep tree) even for users who only
   wanted QEA/XMI parsing.

2. **`lutaml-model` and `lutaml-path` were undeclared.** Both are
   load-time requires in `lib/ea/`:
   - `lib/ea/qea/models.rb`, `base_model.rb`, `services/configuration.rb`,
     `lib/ea/transformations/configuration.rb` — `require "lutaml/model"`
     (BaseModel extends `Lutaml::Model::Serializable`)
   - `lib/ea/xmi/parser.rb` — `require "lutaml/path"`
     (`Lutaml::Path.parse(path)` for XMI path resolution)

   These were silently pulled in transitively via `lutaml-uml` →
   `lutaml-path` and `lutaml-uml` → `lutaml-model`. Once `lutaml-uml`
   moved to dev-only, the transitive pull vanished and 11 specs failed
   with `LoadError: cannot load such file -- lutaml/path`.

## Fix
- Removed `spec.add_dependency "lutaml-uml"` from ea.gemspec.
- Added `spec.add_development_dependency "lutaml-uml"` (needed for
  the spec suite's UML bridge tests).
- Added `spec.add_dependency "lutaml-model"` (runtime).
- Added `spec.add_dependency "lutaml-path"` (runtime).

The Gemfile already declares `gem "lutaml-uml", path: "../lutaml-uml"`
for development, so dev-only declaration in the gemspec is belt-and-
suspenders.

## Verification
- `bundle exec rspec`: 1953 examples, 0 failures, 37 pending
  (unchanged from baseline)
- `gem dependency ea` (after install) no longer pulls `lutaml-uml`
- Standalone `ea` install correctly pulls `lutaml-model` and
  `lutaml-path` as runtime deps

## Lesson
A `require` statement at the top of any lib file is a load-time
contract. If the gemspec doesn't declare the corresponding gem as a
runtime dependency, the gem only works when something else in the
bundle happens to pull that gem in transitively. The dependency
becomes implicit and breaks when the transitive path changes.

Audit rule: every `require "external/gem"` at the top of a `lib/`
file must have a matching `spec.add_dependency` in the gemspec.
