# TODO-D 12 - Connector role/multiplicity labels

## Status: COMPLETE (2026-07-27)

## What changed

Labels renderer refactored to support both XMI and QEA paths:

1. **Property lookup (XMI path)**: When the Association's
   source_id/target_id reference Property IDs, look them up and
   render the role name + multiplicity from the Property fields.

2. **Association fields (QEA path)**: Fall back to the
   Association's own source_role_name, target_role_name,
   source_multiplicity_lower/upper, target_multiplicity_lower/upper
   fields. These are populated by QEA's t_connector.sourcerole/
   destrole/sourcecard/destcard columns.

3. **Default label offset**: When label_boxes aren't populated
   (QEA path — the geometry parser doesn't yet extract them),
   use a default offset (anchor + 5, -10) so labels render near
   the connector endpoints rather than being silently dropped.

## Acceptance

QEA-direct parity measurement:

| Metric | Before | After |
|---|---|---|
| Text delta vs ref | -2728 (14% under) | -883 (5% under) |
| Text overlap avg | 56.0% | 62.8% |

## Remaining

- QEA t_diagramlinks.Geometry parser doesn't extract LLB/LRB
  boxes. Adding that would let labels render at EA's recorded
  pixel positions rather than the default offset.
- The XMI-encoded `<text>` ordering within Labels is still
  suboptimal — EA emits role name and multiplicity in a single
  `<g>` block, we emit each as a separate text element.
