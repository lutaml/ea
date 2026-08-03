# TODO.complete/10: MDG stereotype registry

## Status: done

We have 49 EA-bundled MDG/GML definition files in `spec/fixtures/mdg/`:

- `ea_mdg/*.xml` (46 MDG technology XMLs: BPMN, ArchiMate, SysML, ...)
- `ea_config/gml/GMLStereotypes.xml` (7 GML stereotypes with aliases)
- `ea_config/gml/GMLClassMapping.xml` (UML→GML mapping rules)
- `ea_config/gml/GMLNamespaces.xml` (15+ GML namespace declarations)

The MDG loader is functional but doesn't expose these as a queryable
registry.

## Plan

1. Extend `Ea::Mdg::Registry` (existing) to load all 49 files at startup.
2. Add lookup methods:
   - `Registry#stereotype_by_name(name)` → returns Stereotype with alias,
     tagged value definitions, default color, applicable element types.
   - `Registry#stereotypes_for_technology(tech_name)` → list.
   - `Registry#tagged_value_defs(stereo_name)` → list of tagged value
     definitions.
3. Use this in rendering:
   - Apply default stereotype color from MDG definition (closes some
     colorization gaps).
   - Validate applied stereotypes against MDG definitions.
4. Expose via CLI (`ea mdg list`, `ea mdg show`).

## OCP / MECE

- Registry is the single source of truth.
- New technology = new file in fixtures/ + Registry auto-discovers.
- Renderers and validators query; they don't parse XML.

## Acceptance

- Spec: `Registry.stereotype_by_name("FeatureType")` returns non-nil.
- Spec: registry covers ≥900 stereotypes after loading all 46 MDG files.
- Spec: `ea mdg list` CLI lists technologies.
