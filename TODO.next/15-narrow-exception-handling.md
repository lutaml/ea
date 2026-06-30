# 15 - Narrow Exception Handling

## Status: PARTIALLY DONE (2026-06-27) — residue intentionally left

## Applied
1. **`lib/ea/diagram/configuration.rb`** — narrowed YAML loader rescue from
   `rescue StandardError` to explicit
   `rescue Psych::SyntaxError, Errno::ENOENT, Errno::EACCES, IOError`.
   Unexpected errors now propagate instead of being silently warned away.
2. **`lib/ea/qea/services/database_loader.rb#report_progress`** — kept
   `rescue StandardError` but added justification comment: the progress
   callback is user-supplied with a best-effort contract; isolating its
   failures from the load pipeline is the correct behavior.

## Residue (intentionally not narrowed)
The remaining `rescue StandardError` sites are at trust boundaries where
swallowing-and-continuing is the correct policy:

- **`extractor.rb`** — public API boundary; one bad diagram must not abort a
  batch extract. Already reports the error in the result hash.
- **`base_parser.rb#handle_parsing_error`** — extension point for subclasses
  to override; default swallows to keep parsing the rest of the stream.
- **`qea_parser.rb`, `transformation_engine.rb`** — per-record rescue so one
  malformed EA row doesn't abort the whole load. Pattern matches
  `database_loader.rb`'s per-record rescue (which already catches specific
  `ArgumentError, TypeError, EncodingError` first, falling back to
  `StandardError` for unknown row-level failures).
- **`util.rb#parse_ea_geometry`** — defensive parse of malformed EA geometry
  strings; returning an empty hash on bad input is the documented contract.

Narrowing these further would require defining `Ea::ParseError` and threading
it through every caller, which is a larger refactor than the marginal
debuggability gain justifies today. Revisit if any of these sites start
masking real bugs.

## Files
- `lib/ea/diagram/configuration.rb` — narrowed
- `lib/ea/qea/services/database_loader.rb` — documented

