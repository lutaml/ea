# TODO.release — Streamlined dependency tree

Execute each item in order. Each step depends on the previous.

## Index

| # | Title | Gem | Priority |
|---|---|---|---|
| 01 | [Release lutaml-uml 0.3.0](01-release-lutaml-uml-030.md) | lutaml-uml | BLOCKING — critical path |
| 02 | [Fix lutaml meta-gem broken requires](02-fix-lutaml-meta-gem-requires.md) | lutaml | high — independent of 01 |
| 03 | [Release lutaml 0.11.0](03-release-lutaml-0110.md) | lutaml | high — depends on 02 |
| 04 | [Update ea gemspec pin to ~> 0.3](04-update-ea-gemspec-pin.md) | ea | high — depends on 01 |
| 05 | [Remove ea conditional require workarounds](05-remove-ea-conditional-requires.md) | ea | high — depends on 01 |
| 06 | [Release ea 0.2.0](06-release-ea-020.md) | ea | high — depends on 04, 05 |
| 07 | [Migrate plateau-model to ea gem](07-migrate-plateau-model.md) | plateau-model | medium — depends on 06 |
