# 60 - CLI --theme Option for ea svg Command

## Status: DONE (2026-07-26)

## Context

The `ea svg NAME FILE` CLI command renders a diagram. Users
cannot override the theme from the command line. Adding a
`--theme=ID` flag lets users test different themes without
modifying the QEA/XMI source.

## What needs to change

1. `Ea::Cli::Command::Svg` accepts `--theme=ID` option
2. When provided, sets `diagram.theme = ID` before rendering
3. `--theme=default` resets to no-theme
4. `--theme=list` prints available theme IDs

## Acceptance

- `ea svg MyDiagram model.xmi --theme=119` works
- `ea svg MyDiagram model.xmi --theme=list` lists themes
