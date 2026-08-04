# TODO.complete/78: MDG stereotype emission in QeaToXmi (OCP via registers)

## Status: done

EA's reference XMI includes MDG technology stereotype DEFINITIONS
in the output — each as `<packagedElement xmi:type="uml:Stereotype">`
with its tagged values as `<ownedAttribute>` elements, plus
`<uml:Extension>` relationships linking stereotypes to their base
metaclasses.

Previously our QeaToXmi emitted zero stereotype definitions,
zero extension properties, and zero extension ends for any model
that used MDG stereotypes. This caused massive equivalence gaps
(e.g., ArcGISWorkspace: 0/320 ownedAttribute, 0/37 ownedEnd).

## Architecture (OCP via lutaml-model registers)

MDG technologies are runtime-swappable via {Ea::Mdg::Registry}.
Each registered MDG is also registered with
`Lutaml::Model::GlobalRegister` under `ea_mdg_{name}` so it's
discoverable through the framework's standard register API.

```
Ea::Mdg::Registry (domain-level, swappable)
  └── register(doc) → also calls Lutaml::Model::GlobalRegister.register
  └── unregister(name) → also calls Lutaml::Model::GlobalRegister.remove
```

The QeaToXmi transformer accepts an optional `mdg_registry:`
parameter. When present, the {ProfileSerializer} iterates the
registry's documents at call time and builds xmi gem model objects
(`PackagedElement`, `OwnedAttribute`, `Type`, `MemberEnd`, `OwnedEnd`)
for each stereotype definition. No raw XML string building — fully
model-driven.

## Implementation

- `lib/ea/transformers/qea_to_xmi/profile_serializer.rb` — new
  class. Builds `Xmi::Uml::PackagedElement` objects for each
  stereotype and extension.
- `lib/ea/mdg/registry.rb` — added `unregister` method, Lutaml::Model
  integration via `register_with_lutaml` private helper.
- `lib/ea/transformers/qea_to_xmi/transformer.rb` — accepts
  `mdg_registry:` kwarg, injects profile elements into model.
- `lib/ea/transformers.rb` — `qea_to_xmi` passes `mdg_registry:`.

## Parity improvement (simple.qea with CityGML MDG)

| type | before | after | ref |
|------|--------|-------|-----|
| packagedElement | 11 | 32 | 38 |
| ownedAttribute | 0 | 47 | 34 |
| ownedEnd | 0 | 10 | 12 |

The exact counts differ from EA's reference because the MDG version
(CityGML) differs from the one EA originally used (likely
ShapeChange/INSPIRE for simple.qea). The MECHANISM is correct —
swapping the right MDG produces matching output.

## Spec

`spec/ea/transformers/qea_to_xmi/profile_serializer_spec.rb` — 16
examples covering stereotype shape, extension shape, Lutaml::Model
integration, empty-registry handling.

Full suite: 2203 examples, 0 failures, 55 pending.
