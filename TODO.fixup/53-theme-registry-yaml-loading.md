# 53 - Theme::Registry with YAML Loading

## Status: DONE (2026-07-26)

## Context

Current `ThemeRegistry` has built-in themes hard-coded as Ruby
constants. Like `stereotype_colors.yml`, themes should be
externalized to YAML files for easy editing.

## What needs to change

1. `Ea::Theme::Loader` loads a YAML file into a Definition
2. `Ea::Theme::Registry.load_dir(path)` loads all themes from
   a directory (one YAML file per theme)
3. `config/themes/` directory holds theme definition files:
   - `default.yml` — no theme (uses element-stored values)
   - `119.yml` — Carlito 7pt, gray text, purple-gray borders
4. Registry auto-loads from `config/themes/` on first access

## YAML format

```yaml
id: "119"
name: EA White Theme
font:
  family: Carlito
  size: 7
  unit: pt
text:
  color: "#595959"
  weight_normal: 0
  weight_bold: 700
border:
  color: "#9A8484"
  stroke_width: 1
fills:
  Klass: "#FDFAF7"
  Interface: "#F1ECFA"
  DataType: "#FAF9E6"
  Enumeration: "#E8FDE3"
  PrimitiveType: "#FAF9E6"
```

## Acceptance

- config/themes/default.yml and 119.yml exist
- Registry.load_dir loads them
- YAML format matches Definition fields
- New spec covers YAML loading
