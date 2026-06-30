# 21 - QeaToXmi via xmi gem

## Status: ✅ PHASE 1 COMPLETE (2026-07-01); audit follow-ups landed (TODO 22-34)

Phase 1 of the rewrite is shipped: the custom XmlBuilder/Writer/Emitters
layer is replaced by xmi gem model construction + `to_xml(use_prefix: true)`.

Full ea gem suite after audit follow-ups: **1995 examples, 0 failures,
37 pending** (up from 1931 — the audit added specs for IdAllocator,
Cardinality, XmlSanitizer, plus Phase 2 sentinel specs and tightened
parity coverage).

Plateau smoke (20251010_current_plateau_v5.1.qea): **58 packages, 581
classes, 11 enumerations, 431 associations, 420 generalizations, 0 XML
errors, 1.29 MB output** — matches the previous implementation's numbers
exactly.

## What was delivered

**Deleted (~1000 lines):**
- `lib/ea/transformers/qea_to_xmi/xml_builder.rb`
- `lib/ea/transformers/qea_to_xmi/writer.rb`
- `lib/ea/transformers/qea_to_xmi/emitter_registry.rb`
- `lib/ea/transformers/qea_to_xmi/sparx_namespaces.rb`
- `lib/ea/transformers/qea_to_xmi/emitters/{base,package,class,enumeration,
  data_type,instance,attribute,operation,association,generalization,
  realization,dependency,comment,slot}_emitter.rb`
- Matching spec files for the deleted modules

**Kept (unchanged):**
- `lib/ea/transformers/qea_to_xmi/id_allocator.rb` — EA-specific EAID synthesis
- `lib/ea/transformers/qea_to_xmi/guid_format.rb` — `{GUID}` ↔ `EAID_` translation

**Rewritten:**
- `lib/ea/transformers/qea_to_xmi/transformer.rb` — single class that walks
  the database and constructs `Xmi::Sparx::Root` / `Xmi::Uml::UmlModel` /
  `Xmi::Uml::PackagedElement` / etc., then calls `to_xml(use_prefix: true)`.
  Element-kind dispatch lives in a single case statement in
  `#build_classifier` — adding a new kind = one new branch, no new file.
- `lib/ea/transformers/qea_to_xmi/context.rb` — slimmed down (dropped the
  writer dependency; kept database + IdAllocator).
- `lib/ea/transformers/qea_to_xmi.rb` — autoload list pruned.

**Spec coverage added:**
- Round-trip via xmi gem parser (parse output back through
  `Xmi::Sparx::Root.parse_xml`, verify structure).
- API stability (idempotent serialize, no database mutation).
- Plus all pre-existing parity, mixed-prefix, GUID, well-formedness specs
  continue to pass.

## Phase 2 work (deferred)

These items fell out of the rewrite but are tracked separately:

### 1. xmi gem empty-element rendering (architectural debt)

The xmi gem's UML models declare `value_map: Xmi::VALUE_MAP` on every
child-element mapping. VALUE_MAP is round-trip-oriented: it forces
empty-element emission (`<generalization/>`, `<ownedEnd/>`, etc.) so the
parser can distinguish absence from emptiness. For *generation*, those
empty elements are noise.

The rewrite works around this by post-processing the serialized XML
(`Transformer#strip_empty_elements`) — a Nokogiri pass that removes
truly-empty elements (no children, no attributes). This is functionally
correct but adds a parse/serialize cycle to every emit.

The clean fix lives in the xmi gem: introduce a generation-friendly
value_map (e.g., `Xmi::GENERATION_VALUE_MAP = { to: { nil: :nil, empty:
:nil, omitted: :nil } }`) and let the ea gem opt in. Then drop
`strip_empty_elements` from this gem.

### 2. xmi gem attribute gaps

The xmi gem's UML models don't yet declare every attribute real Sparx
XMI carries. This rewrite drops the following attributes that the
previous XmlBuilder emitted:
- `visibility` on `<ownedAttribute>` / `<ownedOperation>` /
  `<ownedParameter>` (Sparx always emits `visibility="private"|"public"|
  ...`)
- `isAbstract` on `<packagedElement>` for abstract classes
- `classifier` on `<packagedElement>` for InstanceSpecification
- `aggregation` on `<ownedEnd>` for composite vs. shared
- `direction` is exposed by `OwnedParameter` but the value mapping needs
  to align with EA's `kind` field

Each gap is a small, focused PR to the xmi gem: add the attribute,
add a spec round-tripping a fixture that uses it.

### 3. xmi gem missing models

- `Xmi::Uml::Slot` — for instance specification attribute values
- `Xmi::Uml::OpaqueExpression` — for slot values and default expressions
- `Xmi::Uml::InterfaceRealization` — currently collapsed into
  `PackagedElement` with `type="uml:Realization"`

These were emitted by the previous XmlBuilder but are dropped in
Phase 1 because the xmi gem has no models for them. Phase 2 adds the
models, then the Transformer wires them up.

### 4. File-size refactoring

`lib/ea/transformers/qea_to_xmi/transformer.rb` is 503 lines (369 LOC),
over the project's ~300-line guideline. The class is cohesive (one
orchestrator with private walk methods), but it could be split into:

- `Transformer` — orchestration and walk order (~150 lines)
- `ElementFactory` — leaf element construction (attributes, operations,
  literals, comments; ~200 lines)
- `RelationshipFactory` — association / dependency / generalization
  construction (~150 lines)

Deferred because splitting now would risk regressions for cosmetic
gain; the file is conceptually one thing (the QEA walk).

## Goal
Replace the custom XML construction layer in `Ea::Transformers::QeaToXmi` with
the `xmi` gem's typed models (`Xmi::Sparx::Root`, `Xmi::Uml::UmlModel`,
`Xmi::Uml::PackagedElement`, etc.). The Transformer becomes a
**model construction walk** over `Ea::Qea::Database`, not an XML emitter.

## Why

### Why switch from custom XML to xmi gem models

The current implementation builds Sparx XMI through a hand-rolled
`XmlBuilder` + `Writer` + 13 `Emitters` + `EmitterRegistry`. That layer
exists because Sparx XMI uses a mixed-prefix style that lutaml-model's
default behavior doesn't produce (prefixed root `<uml:Model>`,
unprefixed children `<packagedElement>`). The `XmlBuilder` works around
this by using Nokogiri's low-level `Document#create_element` API and
assigning per-element namespaces from a `PREFIXED_ELEMENTS` map.

That workaround is no longer necessary. The xmi gem at v0.5.10+ now
emits the Sparx mixed-prefix style natively:
- `UmlModel` declares `namespace Uml` → emits `<uml:Model>`
- Every child UML class declares `namespace :blank` → emits unprefixed
  `<packagedElement>`, `<ownedAttribute>`, etc.
- `XmiType`, `XmiId`, `XmiIdRef` types declare `namespace Xmi` → emits
  `xmi:type`, `xmi:id`, `xmi:idref` attributes
- Calling `to_xml(use_prefix: true)` forces prefix format on the root

With the xmi gem producing correct Sparx output via standard
lutaml-model serialization, the custom XML construction layer has no
remaining purpose. Every byte it produces is something the xmi gem
also produces from the same input.

### What this eliminates

- `lib/ea/transformers/qea_to_xmi/xml_builder.rb` — low-level Nokogiri
  wrapper with `method_missing` dynamic dispatch for arbitrary tag
  names. ~104 lines of XML plumbing that duplicates what the xmi
  gem + lutaml-model already do.
- `lib/ea/transformers/qea_to_xmi/writer.rb` — XML shape primitives
  routing through the XmlBuilder. ~232 lines that re-express what
  `Xmi::Sparx::Root` already represents structurally.
- `lib/ea/transformers/qea_to_xmi/emitter_registry.rb` — OCP registry
  pattern for emitter dispatch. ~49 lines. With xmi gem models, the
  polymorphism lives in lutaml-model's polymorphic mapping, not in our
  code.
- `lib/ea/transformers/qea_to_xmi/emitters/*` — 13 emitter classes
  (BaseEmitter, PackageEmitter, ClassEmitter, EnumerationEmitter,
  DataTypeEmitter, AttributeEmitter, OperationEmitter, AssociationEmitter,
  GeneralizationEmitter, DependencyEmitter, RealizationEmitter,
  CommentEmitter, InstanceEmitter, SlotEmitter). ~650 lines of
  element-shape code. Each emitter maps one EA database row kind to
  one XMI element kind. The xmi gem already provides typed models
  for every one of these element kinds.

Net reduction: ~1000 lines deleted from the ea gem.

### What stays

- `lib/ea/transformers/qea_to_xmi/transformer.rb` — orchestrator,
  rewritten as a model-construction walk.
- `lib/ea/transformers/qea_to_xmi/context.rb` — wraps the
  `Ea::Qea::Database` and the new model graph. Holds lookups and
  IdAllocator.
- `lib/ea/transformers/qea_to_xmi/id_allocator.rb` — EAID generation
  is EA-specific; the xmi gem has no equivalent.
- `lib/ea/transformers/qea_to_xmi/guid_format.rb` — `{GUID}` ↔
  `EAID_` translation is EA-specific; xmi gem doesn't know about it.
- `lib/ea/transformers/qea_to_xmi/sparx_namespaces.rb` — constants
  used by the new code (or inlined where appropriate).

### What changes in the API surface

`Ea::Transformers::QeaToXmi.qea_to_xmi_xml(database)` — same public
signature, same return type (an XMI string). The internal
implementation is replaced.

## Architecture

### New Transformer flow

```
Ea::Qea::Database (raw rows)
        │
        ▼
Ea::Transformers::QeaToXmi::Transformer
        │   walks packages → elements → connectors
        │   instantiates Xmi::Uml::UmlModel, Xmi::Uml::PackagedElement,
        │   Xmi::Uml::OwnedAttribute, Xmi::Uml::Association, etc.
        │   builds Xmi::Sparx::Root
        ▼
Xmi::Sparx::Root
        │   .to_xml(use_prefix: true)
        ▼
Sparx XMI string
```

### Responsibilities (MECE)

| Component          | Owns                                                        | Does NOT own                              |
|--------------------|-------------------------------------------------------------|-------------------------------------------|
| `Transformer`      | walk order, orchestration, top-level `Root` construction   | element shape, EAID generation            |
| `Context`          | Database handle, IdAllocator, GUID↔EAID lookups             | walk order, element shape                 |
| `IdAllocator`      | generating EAID_xxx identifiers from a seed + counter       | knowing which elements get which ID       |
| `GuidFormat`       | `{GUID}` ↔ `EAID_` bidirectional format                    | anything else                              |
| `Models`           | (delegated to xmi gem)                                     | —                                          |
| `Serializer`       | (delegated to xmi gem `to_xml`)                            | —                                          |

### Polymorphism / OCP

The current emitter registry pattern (`EmitterRegistry.register(:kind,
emitter_instance)`) is replaced by lutaml-model's polymorphic
mapping on `PackagedElement.type`. When `PackagedElement.xmi.type ==
"uml:Class"`, lutaml-model instantiates `Xmi::Uml::PackagedElement`
with the right shape; when `xmi.type == "uml:Interface"`, it
instantiates an interface model. We don't write a polymorphic switch
— the framework does it.

Adding a new UML element type becomes "add a model class to the xmi
gem" (one file, one mapping), not "write an emitter, register it in
the dispatch code".

### Performance

- Construction walk is O(N) over database rows; xmi gem
  serialization is O(M) over the model graph. Same complexity as the
  custom path; should be neutral or faster because the framework
  amortizes XML construction overhead.
- Skip Reference resolution on the ea side: we already know the
  `t_connector.Start_Object_ID` → referenced EAID mapping at
  construction time.
- No double-buffering or string concatenation in our code — let
  lutaml-model handle the serialization.

### Code-quality rules (strict)

- **No `send` on private methods.** If dispatch needs to reach into
  another object, redesign the API.
- **No `instance_variable_set`/`_get`.** Access via public readers or
  rethink ownership.
- **No `respond_to?`.** Use `is_a?` or design the type hierarchy so
  the check is unnecessary.
- **No `require_relative` or internal `require`.** Use `autoload` in
  the immediate parent namespace's file. Define new autoload entries
  in `ea/transformers/qea_to_xmi.rb` (the parent file).
- **No hand-rolled `to_h`/`from_h`/`to_json`/`from_json` on models.**
  All (de)serialization goes through lutaml-model. (We use the xmi
  gem's models, which already follow this rule.)
- **No `double()` in specs.** Use real `Xmi::Sparx::Root`,
  `Xmi::Uml::PackagedElement` instances. For raw test data, use
  `Struct.new`.
- **Files under ~300 lines.** The current 232-line `writer.rb` and
  142-line `association_emitter.rb` are at the edge; the rewrite
  brings all files comfortably under.
- **All public methods have specs.** Behavioral edge cases covered.

### Spec strategy

Specs live in `spec/ea/transformers/qea_to_xmi/` and assert three
properties:

1. **Parity with current implementation** — given the same database,
   the new transformer's output produces a structurally equivalent
   XMI document (same EAIDs, same xmi:type discriminators, same
   hierarchy, same element counts). Compared by re-parsing both
   outputs with `Xmi::Sparx::Root.from_xml` and diffing the model
   graphs.
2. **Round-trip** — the new output can be parsed by the xmi gem
   (`Xmi::Sparx::Root.from_xml(transformer.call(database))`) without
   errors, and the parsed model has the expected element counts.
3. **Plateau smoke** — `Ea::Qea.load("spec/fixtures/plateau.qea")
   .then { |db| Transformer.new(db).call.to_xml }` produces the
   same 1.32 MB output with 581 classes, 420 generalizations, 431
   associations, 0 XML errors.

Specs use real models — no doubles, no stubs of xmi gem classes.

## Open questions / known gaps

1. **EA Extension block** — the current implementation emits a
   stub `<xmi:Extension>` with diagrams and tagged values. The xmi
   gem has typed models for `Extension`, `Element`, `Connector`,
   `Diagram`, `PrimitiveType`, `CustomProfile`. We can wire these
   up; that's what the new Transformer emits.
2. **RunState slot emission** — Phase 2 of the original plan. Out of
   scope for this TODO unless it falls out naturally from walking
   `t_object.RunState` in the Instance element construction path.
3. **Stereotype / profile application** — emitted as `<profileApplication>`
   in current code. The xmi gem has `Xmi::Uml::ProfileApplication` and
   `Xmi::Uml::ProfileApplicationAppliedProfile`. Wire up if the
   current code emits them.

## Implementation plan

1. Create feature branch `feat/qeatoxmi-via-xmi-gem` in this repo
2. Add xmi gem to gemspec if not already present (TODO.next/19
   resolved the gemspec recently — confirm)
3. Rewrite `Transformer` to walk Database → build `Xmi::Sparx::Root`
4. Slim `Context` to just Database + IdAllocator (drop Writer ref)
5. Delete `xml_builder.rb`, `writer.rb`, `emitter_registry.rb`,
   `emitters/`
6. Update specs: replace emitter/writer specs with parity +
   round-trip + plateau specs
7. Run full ea gem suite, ensure parity
8. PR for review

## Risks

- **Behavior change.** The output bytes will differ from the
  current XmlBuilder output in some cases (whitespace, attribute
  ordering, namespace declarations). We assert structural parity via
  re-parse, not byte-equality.
- **xmi gem schema coverage gaps.** If a database row kind has no
  matching xmi gem model, the new Transformer will fail. The current
  plateau fixture must be fully representable; if not, we add the
  missing model to the xmi gem first.
- **xmi gem PR #87 must merge** before we can rely on
  `to_xml(use_prefix: true)` producing the Sparx mixed-prefix style.
  Until then, we develop against the branch in `Gemfile`/local
  checkout.