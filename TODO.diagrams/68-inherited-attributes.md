# TODO-D 68: Association-derived virtual properties (phantom attributes)

## Status: open (discriminator unresolved)

EA renders some association SourceRole values as virtual
"property" attributes inside the source classifier's attribute
compartment. For example, ImplicitGeometry has 4 associations to
CityFurniture with SourceRoles lod1..4ImplicitRepresentation.
EA renders "+lod1ImplicitRepresentation" inside ImplicitGeometry's
attribute compartment on every diagram where ImplicitGeometry is
placed with an expanded attribute compartment.

## Investigation findings

The phantom attributes come from t_connector.SourceRole on
Association and Aggregation connectors. In the plateau QEA:
- 206 Aggregations have SourceRoles
- 172 Associations have SourceRoles

Not all SourceRoles render as virtual attributes. The discriminator
that gates rendering has NOT been identified. Adding all 378
SourceRoles as properties causes massive over-rendering (text
delta: +20,000). The correct subset is much smaller.

### What was tried

1. **All SourceRoles as properties**: text +20k — far too many.
   The vast majority of SourceRoles do NOT render in EA output.

2. **Only when connector NOT on current diagram**: incorrect —
   on the ImplicitGeometry diagram, the lod* connectors ARE on
   the diagram AND the phantom attrs still show.

3. **Only for GML stereotypes (Type/FeatureType)**: promising
   but not all "Type" stereotyped classifiers show SourceRole
   attrs on every diagram. CityGMLCore shows ImplicitGeometry
   WITHOUT the lod texts (element is in collapsed mode).

### What's known

- SourceRoles render ONLY when the element's attribute compartment
  is visible AND expanded (has NSL/font settings in ObjectStyle).
- The position of phantom attr texts in the ref SVG is OUTSIDE
  any element rect (floating) on some diagrams, suggesting EA
  places them at connector-label positions rather than inside
  the attribute compartment.
- Multiple phantom attrs at the same position suggests overlap
  rendering (all at same x,y) which is characteristic of connector
  end-labels, not attribute-compartment lines.

### Next steps

1. Investigate whether the phantom attrs are actually connector
   LABELS (from $LLB/$LLT geometry) rather than attribute
   compartment lines. The position (412, 473) doesn't match any
   element's attribute compartment area.

2. Check if the phantom attrs come from a per-diagram setting
   like "Show inherited/association attributes" flag in the
   t_diagram StyleEx or PDATA.

3. If they ARE attribute-compartment lines (not labels),
   identify the precise subset of SourceRoles that EA renders
   (maybe only when the connector's DestRole is empty AND the
   SourceRole matches a naming convention).
