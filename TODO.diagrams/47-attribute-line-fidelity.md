# TODO-D 47: Attribute line fidelity (qualified prefix + multiplicity shorthand + primitive type strip)

## Symptom (largest single source of text delta)

Aggregated text diff against 185 plateau diagrams:

```
Ref has but we don't:        We have but ref doesn't:
  qualified_name:  539         qualified_name: 1016
  other:          1501         other:           462
```

Most "qualified_name" cases are attribute lines on inherited
properties. Reference renders:

```
core::mimeType: gml::CodeType [0..1]
core::elements: double [16] {ordered}
```

We render:

```
mimeType: gml::CodeType [0..1]
elements: xs::double [16..16]
```

## Three distinct bugs

### A. Missing namespace prefix on inherited properties

When a class displays a property inherited from a parent in a
different package, EA prepends the parent's package name to the
property name (`core::mimeType`). For own properties, no prefix.

Discriminator: the property's `owner_id` (the classifier that
declares it) — if that classifier's `package_id` differs from the
displayed classifier's `package_id`, render the prefix.

### B. Multiplicity shorthand `[N]` not `[N..N]`

When `multiplicity_lower == multiplicity_upper`, EA renders `[N]`
(single value), not `[N..N]`. We always render the range.

### C. Primitive type strip

When the type is a primitive (xs:string, xs:double, xs:integer,
xs:date, xs:gYear, xs:boolean, xs:anyURI, etc.), EA strips the
namespace prefix and renders just `string`, `double`, etc.

Verified against ref: `double` not `xs::double`, `string` not
`xs::string`. The exception is when the property's type is an
in-model Classifier (not a primitive) — then qualified form is
kept (`gml::CodeType`, `core::TransformationMatrix4x4`).

### D. `{ordered}` modifier on ordered properties

When `is_ordered == true` and multiplicity is non-singleton,
EA appends ` {ordered}` after the multiplicity.

## Acceptance

- All four rules implemented in `AttributeRenderer.line_for`.
- Property model exposes the source classifier (for prefix logic).
- Spec coverage for each rule (own/inherited, primitive/typed,
  lower==upper, ordered/unordered).
- Bench text overlap → ~90% (from 64.5%).

## Bench impact estimate

Closes ~600 text deltas (the qualified_name category) plus ~1000
"other" deltas that are attribute lines with wrong format.
