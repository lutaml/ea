# 57 - Theme Specs and Integration Test

## Status: DONE (2026-07-26)

## Context

The Theme refactor (TODO 51-56) is a major architectural change.
Comprehensive specs are needed to verify:
1. YAML loading
2. Definition immutability + #with
3. Registry OCP (register new themes)
4. Diagram#theme API (get/set/override)
5. Integration: render with custom theme

## What needs to change

1. `spec/ea/theme/definition_spec.rb` — value object behavior
2. `spec/ea/theme/registry_spec.rb` — registry + YAML loading
3. `spec/ea/theme/loader_spec.rb` — YAML parsing
4. `spec/ea/model/diagram_theme_spec.rb` — Diagram#theme API
5. Integration spec: render with custom theme, verify output

## Acceptance

- All spec files created with comprehensive coverage
- >90% line coverage on Ea::Theme::*
- All existing specs pass
