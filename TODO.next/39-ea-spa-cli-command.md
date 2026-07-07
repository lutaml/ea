# 39 - `ea spa` CLI command — generate SPA from any format

## Status: DONE (2026-07-07)

## Problem
The pipeline QEA → SPA exists programmatically:

```ruby
document = Ea::Transformations.parse("model.qea")
repo = Lutaml::UmlRepository::Repository.from_document(document)
Lutaml::UmlRepository::StaticSite::Generator.new(repo, output: "out.html").generate
```

But there's no CLI command exposing it. Users have to write Ruby to
generate a SPA from a QEA or XMI file.

## Fix

### New: `lib/ea/cli/command/spa.rb`
`Ea::Cli::Command::Spa` — a Thor command class. Wires:
1. `Ea::Transformations.parse(file)` — auto-detects QEA vs XMI
2. `Lutaml::UmlRepository::Repository.from_document(document)`
3. `Lutaml::UmlRepository::StaticSite::Generator.new(repo, options).generate`

Outputs a single-file Vue IIFE HTML by default. Options:
- `--output PATH` (default: `<basename>.html` next to the input)
- `--mode MODE` (`single_file` default; `multi_file` alternative)

### Updated: `lib/ea/cli/app.rb`
Registers the new `spa` subcommand:

```
ea spa FILE [--output=PATH] [--mode=MODE]
```

### Updated: `lib/ea/cli/command.rb`
Adds `autoload :Spa, "ea/cli/command/spa"` (autoload-only per project
rule — no require_relative).

## Verification
- `ea spa spec/fixtures/basic.qea` produces a ~300KB single-file HTML.
- `ea spa spec/fixtures/basic.xmi --output /tmp/x.html` produces the
  XMI-derived SPA.
- New spec in `spec/ea/cli/command/spa_spec.rb` exercises both QEA
  and XMI inputs and asserts file generation + minimum size.

## Architecture
- One CLI command class per file under `lib/ea/cli/command/`.
- The command class is a thin coordinator — the heavy lifting
  (parsing, repository wrapping, SPA generation) lives in already-
  tested libraries.
- The command requires `lutaml/uml_repository/static_site` at load
  time (it's the bridge dependency documented in TODO.next/20).
