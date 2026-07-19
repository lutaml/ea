# 10 - Rework `ea spa` CLI Command

## Status: DONE (2026-07-19)

## Problem

`Ea::Cli::Command::Spa` currently delegates to
`Lutaml::UmlRepository::StaticSite::Generator`, forcing the QEA →
UML transform. The new pipeline is QEA → `Ea::Model` → `Ea::Spa`.

## Approach

Rewire to:
1. `Ea.parse(file)` → source-specific model (QEA Database or XMI
   Root)
2. Source adapter → `Ea::Model::Document`
3. `Ea::Spa::Projector` → skeleton + shards + search index
4. `Ea::Spa::Output::Strategy` → HTML/JSON on disk

Output mode auto-selected by payload size, overridable by
`--mode=single_file|sharded` flag.

## Files

- `lib/ea/cli/command/spa.rb` — reworked
- `lib/ea/cli/command/repository_builder.rb` — extended to feed
  the new pipeline
- `spec/ea/cli/spa_spec.rb` — end-to-end on a small fixture

## Verification

- `ea spa path/to/small.qea` produces a valid SPA
- `ea spa path/to/plateau-model/20251010_current_plateau_v5.1.qea`
  completes in minutes, not hours
