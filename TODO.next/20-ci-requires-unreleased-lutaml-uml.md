# 20 - CI requires an unreleased lutaml-uml

## Status: BLOCKED — waiting on lutaml-uml release

## Problem

`bundle exec rspec` for the `ea` gem requires `Lutaml::UmlRepository`
(see `spec/spec_helper.rb:6` and several specs under `spec/ea/qea/` and
`spec/ea/diagram/`). `UmlRepository` lives in
`lib/lutaml/uml_repository.rb` in the lutaml-uml source tree.

No published version of `lutaml-uml` ships that file (audited
2026-06-30: 0.2.0, 0.2.12, 0.3.0, 0.4.3, 1.0.0 all lack it). The
constant only exists in the local checkout at
`/Users/mulgogi/src/lutaml/lutaml-uml` and is unreleased.

The same applies to several `Lutaml::Uml::*` constants the ea bridge
references (e.g. `Lutaml::Uml::UmlClass`, which 1.x renamed to
`Lutaml::Uml::Class`).

## Consequence

`ea`'s CI cannot go green until a new `lutaml-uml` version is released
containing:

1. `lib/lutaml/uml_repository.rb` (the `Lutaml::UmlRepository` namespace)
2. The pre-1.x `Lutaml::Uml::*` constant names the bridge code uses

## Current state of the ea PR

- Gemfile uses a conditional path-or-rubygems selector for
  `lutaml-uml`/`canon` (`EA_FORCE_RUBYGEMS=1` forces rubygems mode for
  testing the CI-resolved versions locally).
- Gemfile.lock is committed in rubygems mode so CI installs a
  published `lutaml-uml` rather than failing on a missing sibling path.
- ea.gemspec pins the dev dep to `~> 0.2.0` to match the API the spec
  suite is written against.
- CI on this PR will fail with `LoadError: cannot load such file --
  lutaml/uml_repository` at `spec_helper.rb` load time. That failure
  is the clearest signal we can give CI until the matching lutaml-uml
  is released.

## Unblocking steps

When a new `lutaml-uml` is released with `uml_repository`:

1. Bump ea.gemspec dev dep to the new version range
2. Regenerate Gemfile.lock in rubygems mode
3. Re-run CI — should be green

## Architectural follow-up (out of scope here)

The ea gem is documented as standalone with an optional UML bridge.
The spec suite currently requires the bridge unconditionally in
`spec_helper.rb`. A cleaner architecture would:

- Move bridge specs into a separate `spec/bridge/` directory
- Gate them on `defined?(Lutaml::UmlRepository)` (skip when not loadable)
- Keep `spec_helper.rb` standalone-only

That way the standalone subset of `ea` can be tested in CI without
any lutaml-uml dependency at all, and the bridge specs run only in
environments that have a compatible lutaml-uml.
