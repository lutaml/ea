# TODO.complete/21: `ea render` unified rendering command

## Status: done

Consolidate the existing `svg` command into a more general `render`
command that supports multiple output formats.

## Plan

```
ea render model.qea --all --format svg     # all diagrams as SVG (current default)
ea render model.qea --diagram "indoor"     # specific diagram
ea render model.qea --format png           # PNG via rsvg/headless (future)
ea render model.qea --format pdf           # multipage PDF (future)
```

## Migration

- `ea svg ...` remains as alias for `ea render --format svg`.
- New `--format` flag selects output.
- PNG/PDF are future; only `svg` implemented now.

## Acceptance

- Spec: `ea render model.qea --all` produces SVG for every diagram.
- Spec: `--format svg` and `ea svg` produce identical output.
