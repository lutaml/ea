# TODO-D 86: Foreign-package rule over-suppression (parent-ghost)

## Status: open (rolling)

The current `parent_package_represented_on_diagram?` check in
`lib/ea/svg/ea_emitter/elements.rb` suppresses the off-canvas
parent-class italic ghost line when ANY placed element shares
the parent's package. This rule was added to fix the Building
diagram's spurious _Feature/_AbstractGeometricAggregate ghosts.

## Trade-off

  | Rule state | Text delta | Effect |
  |---|---|---|
  | Rule ENABLED (current) | -40 | Some valid ghosts suppressed |
  | Rule DISABLED | +60 | Some invalid ghosts rendered |

Net: rule removes 100 ghosts total (60 invalid + 40 valid).

## Hypotheses tested (all DISPROVEN)

  1. **Package match** (current rule) — over-suppresses
  2. **Parent name in diagram name** — too narrow
  3. **Parent stereotype vs child stereotype** — all cases have
     identical stereotypes, no discriminator
  4. **Parent abstract flag** — both abstract and non-abstract
     parents render on indoor; both don't on Building
  5. **Parent's package_id is top-level** — all parents are
     top-level; no discriminator

## Valid vs invalid samples

| Diagram | Child | Parent | Parent pkg | Renders in ref? |
|---|---|---|---|---|
| indoor | Room | _CityObject | core | YES |
| indoor | _AbstractBuilding | _Site | core | YES |
| tran_2 | TrafficVolumeAttribute | RoadAttribute | uro | YES |
| bldg_1 | BuildingDetailAttribute | BuildingAttribute | uro | YES |
| Building | Address | _Feature | gml | NO |
| Building | _CityObject | _Feature | gml | NO |
| Building | _Solid | _GeometricPrimitive | gml | NO |

The discriminator between YES (render) and NO (suppress) cases
is NOT in t_object, t_connector, or any field we currently parse.

## Remaining candidates (untested)

1. A per-element flag in t_diagramlinks or t_diagramobjects
   (e.g., a per-element "show parent" flag).
2. A diagram-level StyleEx flag we haven't decoded.
3. The depth of the inheritance chain (immediate parent vs
   grandparent).
4. A Package-level attribute (e.g., "abstract package" vs
   "concrete package").

## Strategic block

The discriminator requires either EA source access or
significant reference-SVG triangulation. Each additional rule
attempted in this conversation has either over-suppressed
valid cases or under-suppressed invalid ones. The current rule
is the best trade-off found.
