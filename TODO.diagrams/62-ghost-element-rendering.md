# TODO-D 62: Ghost element rendering (off-canvas connector endpoints)

## Status: open

EA phantom-renders classifier names near connector endpoints that
reference elements NOT placed on the current diagram. These "ghost
elements" appear as italic class names (e.g. `_CityObject`,
`_Site`, `_Geometry`) at the connector's off-canvas end. They are
NOT in `t_diagramobjects` for the diagram but ARE referenced by
`t_connector.Start_Object_ID` / `End_Object_ID` of connectors
that ARE on the diagram.

## Evidence (plateau QEA, "indoor" diagram)

- `_CityObject` does not appear in `t_diagramobjects` for the
  indoor diagram.
- It IS referenced by connectors on the indoor diagram (e.g.
  generalizations from `Room` to `_CityObject`).
- EA renders the name as 5+ separate italic `<text>` elements at
  different positions, one per connector endpoint.

## Approach

1. **Source side**: in `DiagramBuilder`, walk every renderable
   connector and look up its source/target object via
   `database.find_connector` → `start_object_id`/`end_object_id` →
   `database.find_object`. When the object is NOT placed on this
   diagram (no entry in `t_diagramobjects`), synthesise a
   "ghost element" annotation on the connector: the off-canvas
   end's classifier name + a virtual anchor position (probably
   the on-canvas endpoint).

2. **Model side**: add `ghost_labels` to `DiagramConnector` —
   a collection of `(name, end_kind, anchor_offset)` tuples.

3. **Renderer side**: emit each ghost label as an italic `<text>`
   at the connector's endpoint, offset to one side. Match EA's
   offset rules (need to reverse-engineer from reference SVGs).

## Impact

Closing the text gap from -292 to near 0 on plateau QEA. Most of
the missing text delta comes from ghost labels:
- indoor: -17 (mostly `_CityObject`)
- frn_1: -7
- cons_1: -6
- tran_2: -5
- bldg_1: -6 (BuildingAttribute)
- and 10+ more diagrams with -1 to -5 each.

Combined: ~80-100 missing ghost labels across the plateau.

## Related

- TODO-D 26 (Investigate phantom class headers from connector
  endpoints) is the older writeup of the same issue.
