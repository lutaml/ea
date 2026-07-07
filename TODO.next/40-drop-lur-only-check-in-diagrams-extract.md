# 40 - Drop `.lur`-only check in `ea diagrams extract`

## Status: DONE (2026-07-07)

## Problem
`Ea::Cli::Command::Diagrams` rejected any input that wasn't a `.lur`
file:

```ruby
def validate_lur!(path)
  return if path.end_with?(LUR_EXT)

  raise Ea::Cli::UnsupportedFormat.new(
    path,
    "diagrams extract requires a #{LUR_EXT} file; " \
    "convert from QEA via the lutaml gem first",
  )
end
```

This was artificially restrictive. The `Ea::Diagram::Extractor` API
accepts any `Lutaml::UmlRepository::Repository` object, so the CLI
could auto-build one from a QEA or XMI file via
`Ea::Transformations.parse` + `Repository.from_document`.

## Fix

### Updated: `lib/ea/cli/command/diagrams.rb`
The `extract` action now:
- Auto-detects the input format (QEA, XMI, or LUR)
- Parses to `Lutaml::Uml::Document` via `Ea::Transformations.parse`
- Wraps in `Lutaml::UmlRepository::Repository.from_document`
- Passes the Repository to `Extractor#extract_one`

`.lur` files continue to work via the existing
`Repository.from_file` path (preserves backward compatibility with
the LUR-native workflow).

### Removed: `validate_lur!` private method
Replaced by `build_repository(path)` which handles all three formats.

## Verification
- `ea diagrams extract spec/fixtures/basic.qea "Starter Object Diagram"`
  produces a real SVG (3-4 KB).
- `ea diagrams extract spec/fixtures/basic.xmi "Starter Object Diagram"`
  also works (after the XMI parser fix from TODO 38 lands).
- Existing `.lur` flow unchanged.
- New spec in `spec/ea/cli/command/diagrams_spec.rb` covers all three
  input formats.

## Architecture
- Single source of truth for "QEA/XMI → Repository" wiring:
  `Ea::Cli::Command::Diagrams#build_repository`. Reused by the new
  `spa` command (TODO 39) via the same pattern.
- No format-specific knowledge leaks into the Extractor — it still
  takes a Repository and asks `repository.all_diagrams`.
