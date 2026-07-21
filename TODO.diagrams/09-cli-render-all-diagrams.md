# 09 - CLI: Render All Diagrams from a Source

## Status: DONE (2026-07-21)

## Problem

`ea svg NAME FILE` renders one named diagram. For batch
regeneration of all diagrams (e.g. plateau-model deploy), we need
a way to render every diagram in a source file.

## Approach

Add `ea svg --all FILE [--output-dir=PATH]` mode. Iterates every
diagram in the model, names the output file by diagram id (e.g.
`EAID_0016F797_....svg`).

## Files

- `lib/ea/cli/command/svg.rb` (extend)
- `spec/ea/cli/svg_command_spec.rb`

## Verification

- `ea svg --all plateau.xmi --output-dir=/tmp/svgs` produces one
  SVG per diagram.
