# TODO-D 76: basic.qea polygon under-render (-6) and path over-render (+6)

## Status: open

After the aggregation arrow fix (TODO-D 73), basic.qea reached
22/22 diagrams matched within tolerance, but two aggregate deltas
remain:

  - polygon: ours=95, ref=101 (-6)
  - path: ours=208, ref=202 (+6)

## Per-diagram pattern

  - Package Dependencies (0EDEA6EF): polygon +3
  - Basic Class Diagram with Attributes (4F421236): polygon -2
  - Basic Class Diagram with Operations (2AAB709F): polygon -2
  - Basic Class Diagram with Receptions (4DBDAB9E): polygon -2
  - Basic Class Diagram with Attributes and Operations (D2FA55D3): polygon -2
  - Basic Class Diagram with Multiplicities (78030266): polygon -1
  - Basic Class Diaram with Roles (6E95B74E): polygon -1
  - Domain Model (E325B9D8): polygon +1

## Likely cause (Basic Class Diagram family)

For the 4 diagrams with polygon=-2, we're missing 2 small triangle
polygon markers per diagram. These are likely Generalization arrow
triangles that we suppress somewhere.

The +3 polygon overshoot on "Package Dependencies" is likely a
package-import marker (anchor shape) that EA omits.

## Path over-render (+6)

After the aggregation arrow fix, the +16 path over-render on the
outlier closed (to 0). The remaining +6 paths are likely from
similar marker issues on the diagrams above.

## Next step

For each affected diagram, compare our markers vs ref's markers.
Identify which marker emission is incorrect.
