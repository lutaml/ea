# 56 - Theme Definition YAML Files

## Status: DONE (2026-07-26)

## Context

Theme definitions should be in human-editable YAML files (like
`stereotype_colors.yml`), not hard-coded Ruby constants.

## What needs to change

1. `config/themes/default.yml` — no theme override
2. `config/themes/119.yml` — EA White Theme (Carlito 7pt)
3. Both follow the YAML format defined in TODO 53
4. Ea::Theme::Loader auto-loads from config/themes/ on first
   Registry access

## default.yml

```yaml
id: default
name: Default (element-stored values)
font:
  family: null
  size: null
  unit: px
text:
  color: "#000000"
  weight_normal: 400
  weight_bold: 700
border:
  color: "#000000"
  stroke_width: 2
fills: {}
```

## 119.yml

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
  Ea::Model::Klass: "#FDFAF7"
  Ea::Model::Interface: "#F1ECFA"
  Ea::Model::DataType: "#FAF9E6"
  Ea::Model::Enumeration: "#E8FDE3"
  Ea::Model::PrimitiveType: "#FAF9E6"
```

## Acceptance

- Both YAML files exist and parse correctly
- Loader loads them into Registry
- Registry.lookup("119") returns Definition with all fields
