# TODO-D 70: MDG Technology Support

## Status: Phases 1 & 2 complete; Phase 3 deferred

EA's MDG (Model Driven Generation) technologies bundle UML
profiles, reference models, and toolbox definitions in a single
XMI file. When EA loads an MDG, the MDG's classes/attributes/
stereotypes become available to all models — including inherited
attribute rendering when a classifier's stereotype maps to an
MDG-defined metaclass.

## Architecture (shipped)

```
Ea::Mdg                                    # standalone namespace
  ├─ Document         # one MDG file's parsed model
  │    ├─ ClassifierEntry  (id, name, package_name, properties)
  │    ├─ PropertyEntry    (name, type_name, visibility, mult)
  │    └─ GeneralizationEntry (specific_id, general_id)
  ├─ Loader           # XMI parser → Document
  └─ Registry         # multi-MDG lookup, ancestor walking
```

Integration:

- `Ea::Sources::Qea::Adapter.from_path(path, mdg_registry: nil)`
- When `mdg_registry:` is wired, `ClassifierBuilder#properties_for`
  merges MDG-inherited attributes into the classifier's property
  list.
- Backward-compatible: omitting `mdg_registry:` preserves prior
  behavior exactly.

## Verified against reference MDG files

- `MDG ISO19103.xml` (12 classifiers, 5 packages)
- `ISO 19103 Edition 1 XML.xml` (62 classifiers, 68 generalizations,
  properties under UML:Classifier.feature)
- Ancestor walk yields correct inherited properties
  (e.g. UnitsList → StandardUnits → 11 properties)

## What's still needed for plateau parity

The plateau phantom attributes (`+lod1ImplicitRepresentation`
on `ImplicitGeometry`, `+boundedBy` on `_CityObject`, etc.) come
from a **CityGML/GML MDG** that is not in the user's
`~/src/lutaml/xmi/references/ImplementationModels/` directory.

To close those specific gaps:
1. Obtain the CityGML/GML MDG technology XML file.
2. Pass it via `mdg_registry:` when loading the plateau QEA.
3. The classifier's `Type` stereotype will resolve to the MDG's
   `Type` class, and its ancestor properties will merge in.

This is data-availability, not architecture. The plumbing works.

## Phase 3 (deferred)

- Stereotype definition extraction (UML:Profile/Stereotype) for
  applying tagged values from MDG stereotype definitions.
- CLI subcommand: `ea mdg list` / `ea mdg show <name>`.
- Toolbox definition parsing (for future toolbox rendering).

## Test coverage

- `spec/ea/mdg/loader_spec.rb` (6 specs)
- `spec/ea/mdg/registry_spec.rb` (8 specs)
- `spec/ea/sources/qea/mdg_integration_spec.rb` (3 specs)
- Total: 17 new specs; full suite 1839 examples, 0 failures.
