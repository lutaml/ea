# TODO-D 60: TestSchema association marker encoding (-1 path)

## Status: open (blocks 1 test.qea diagram)

test.qea TestSchema is at text_delta=0 but path_delta=-1.

## Symptom

Ref renders a particular Association connector with an open
`<path>` V-shape arrow at the target end. We render the connector
line but no arrow — the marker is suppressed somewhere in our
dispatch.

## Likely cause

The connector is on a Logical (not Object) diagram so our
"Object diagrams suppress Association arrows" rule doesn't apply.
Yet we still don't emit the marker. The Markers#specs_for path
returns no specs because... needs investigation.

## Plan

1. Render TestSchema and identify which connector is missing its
   arrow.
2. Trace through Marker::Registry.specs_for and confirm ArrowPath
   is registered and returns a spec.
3. Trace through Markers#entries_for and check whether the spec is
   being filtered out (suppress_arrow? or render_shape returns nil).
4. Most likely culprit: `unit_vector` returns nil because tip and
   base are coincident (connector shorter than 1 unit vector step).

## Verification

- test.qea TestSchema: path_delta -1 → 0.
- test.qea: 1/2 → 2/2 strict-perfect (100%).

## Why deferred

Small delta (-1 path) and the fix likely requires non-trivial
debugging of the unit-vector geometry for very short connectors.
