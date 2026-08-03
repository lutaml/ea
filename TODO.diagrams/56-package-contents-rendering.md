# TODO-D 56: Package contents rendering (DONE)

## Before

When a diagram's `t_diagram.ShowPackageContents` flag was non-zero,
EA renders each Package element with:
- A 2-line tab when the package has a stereotype («applicationSchema»)
- A body compartment listing child classifiers and sub-packages as
  "+ Name" rows
- A per-row icon whose shape encodes the child's type

Our renderer produced only the bare folder silhouette. All test.qea
"Test Model" diagrams and basic.qea "Package Imports" diagrams
under-rendered by ~70 elements each.

## After

### Source side

- `Ea::Sources::Qea::PackageBuilder#stereotype_refs_for`: now reads
  the t_object.Stereotype column for the package's mirror row
  (matched by ea_guid). EA stores the stereotype on t_object, not
  t_package.
- `Ea::Sources::Qea::DiagramBuilder#package_contents_enabled?`:
  threads `show_package_contents` (non-zero t_diagram column) into
  `Ea::Model::Diagram`.
- `Ea::Model::Diagram#show_package_contents`: boolean attribute
  controlling whether the package-contents compartment is rendered.

### Render side

- `Ea::Svg::EaEmitter::Element::PackageShapeRenderer`: now accepts
  an optional `stereotype:` argument. When present, the tab grows
  to 36px tall (vs 20px) and renders two left-aligned text lines
  («stereotype» + name). Tab width is fixed at 105px (EA convention).
- `Ea::Svg::EaEmitter::Compartment::PackageContents`: new
  compartment module that renders the body's child rows. Each row
  is one `<text>` element ("+ Name") plus a small per-type icon.
- `Ea::Svg::EaEmitter::Element::RowIconRenderer`: new renderer for
  the per-row icons. Three kinds:
  - `:enumeration` (12×13 green rect + 7 paths) — used for
    Enumeration classifiers or Klass with stereotype "enumeration".
  - `:package` (13×9 folder rect, no paths) — used for sub-Packages.
  - `:default` (11×14 + 11×4 rects + 7 paths) — used for other
    Classifiers (Klass, DataType, etc.).
- `Ea::Svg::EaEmitter::Compartment::Shape`: threads the package's
  stereotype to PackageShapeRenderer.
- `Ea::Svg::EaEmitter::Elements`: computes `package_content_lines`
  for Package model elements when `diagram.show_package_contents`
  is truthy. Children include both Classifier and sub-Package
  instances; the icon kind is chosen by classifier type or
  "enumeration" stereotype.

### Specs

- Updated `spec/ea/svg/ea_emitter/compartment_spec.rb` to include
  PackageContents in the expected ALL list.

## Verification

- simple.qea: 2/2 (100% strict-perfect) — unchanged.
- basic.qea: 21/22 matched within tolerance (up from 20/22).
  14/22 strict-perfect (up from 7/22).
- test.qea: 2/2 matched within tolerance. Test Model is strict
  perfect (was shape_delta=71). TestSchema still has a small
  pre-existing -4 text gap unrelated to package contents.
- Plateau: rect/path/polygon deltas unchanged (text improved
  slightly, -626 → -615, from stereotype rendering).
- 1767 specs pass, 0 failures.

## Remaining gaps

- test.qea TestSchema: -3 text. Ref includes «voidable» constraint
  stereotype, "constraints" header, and "{pattern}" annotation that
  we don't render yet. Pre-existing.
- basic.qea Domain Model: rect=+3 (Concept boxes drawn as rects
  but ref uses bezier paths). Pre-existing.
- basic.qea Class-diagram-with-X diagrams: path deltas from
  association marker encoding differences (QEA polygon vs XMI
  arrow path). Pre-existing.
- basic.qea Object diagrams: missing instance-name underline paths
  and instance label format ("Object 01 / roleOne: Class A"). Needs
  an InstanceSpecification model. Pre-existing.

## Follow-up commits

`feat: promote enumeration-stereotyped Class to Enumeration model` —
ClassifierBuilder now treats a Class with stereotype "enumeration"
as an Enumeration. Closes 1 additional text delta on TestSchema
(-4 → -3).

`feat: constraints compartment (italic header + {name} expression)` —
Adds Ea::Model::Constraint, reads t_objectconstraint in the QEA
classifier builder, and renders via Compartment::Constraints +
Element::ConstraintRenderer. Closes 2 text deltas on TestSchema
(-3 → -1).

`feat: render attribute stereotypes as separate text lines` —
AttributeRenderer.lines_for inserts «stereotype» entries before
stereotyped properties. Closes the final TestSchema text gap
(-1 → 0).

`feat: instance-name underline for object diagrams` — Object
diagrams draw a horizontal underline below each instance name.
New Compartment::InstanceUnderline module fires for diagrams
where diagram_type=="Object". RenderContext gains a :diagram
field. Improves path delta on all 4 basic.qea object diagrams.

`feat: «import» markers for Package connectors` — New
Marker::PackageImport kind emits both a closed trapezoid at the
source end and an open V-arrow at the target end of Package
(«import») connectors. Closes the basic.qea Package Imports
path delta (-4 → 0).

`feat: Object diagram — divider + suppress arrows` — Object
diagrams render associations as instance-level links without
navigability arrows. Markers suppresses :arrow specs for
Association connectors when diagram_type=="Object". HeaderDivider
gains a diagram-type-aware discriminator: on Object diagrams the
divider is shown when bounds.height > 50 (matches EA's "has slot
compartment" heuristic). Closes path deltas on all 4 basic.qea
Object diagrams. Starter Object Diagram is now strict-perfect.

## Final state

- simple.qea: 2/2 strict-perfect (100%).
- basic.qea: **16/22 strict-perfect**, 22/22 within tolerance.
- test.qea: 1/2 strict-perfect (Test Model perfect; TestSchema at
  text=0, path=-1).
- Plateau: rect -221, path -280, polygon -6, text -615.
- 1800 specs pass, 0 failures.

## Remaining gaps (all pre-existing, out of scope)

- test.qea TestSchema: -1 path (association marker encoding).
- basic.qea Domain Model: +3 rect (Concept boxes drawn as rects
  but ref uses bezier paths in a "domain class" style with
  Comic Sans MS italic font).
- basic.qea Classes (×2): +1 path each (extra arrow marker on
  tree-routed Association connectors — source discriminator not
  yet identified; same connectors on Multiplicities render WITH
  arrows in ref, so the rule is more subtle than waypoint count).
- basic.qea Object diagrams (×3 with text deltas): instance label
  format ("Object 01 / roleOne: Class A"), slot value renderings
  ("attr = value"), and "(from package)" subtitle. Needs
  InstanceSpecification model.
- Association marker encoding: QEA polygon vs XMI arrow path
  discriminator not yet identified.
