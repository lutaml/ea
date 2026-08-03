# TODO-D 80: Basic.qea Generalization triangle markers as polygons

## Status: open (initial hypothesis disproven)

On 4 basic.qea diagrams ("Basic Class Diagram with Attributes",
"Operations", "Receptions", "Attributes and Operations"), ref
shows 2 extra triangle `<polygon>` markers per diagram that we
emit as `<path>` arrows instead.

## Per-diagram delta

  - Attributes:    -2 polygons (and +2 paths)
  - Operations:    -2 polygons (and +2 paths)
  - Receptions:    -2 polygons (and +2 paths)
  - Attributes+Operations: -2 polygons (and +2 paths)
  - Multiplicities: -1 polygon
  - Roles:         -1 polygon
  - Package Dependencies: +3 polygons (over-render — likely
    package_import marker issue)
  - Domain Model:  +1 polygon

Net basic polygon delta: -6.

## Initial hypothesis (DISPROVEN)

Tried: emit `:triangle` instead of `:arrow` for Association with
direction="Unspecified".

Result: Over-corrected. basic polygons went from -6 to +15 because
many basic.qea "Unspecified" Associations DO want arrow markers,
not triangles. The discriminator must be narrower.

## Next investigation

The 4 failing diagrams share: 2 Association connectors, both
"Unspecified", connecting Class A → Class B.

Inspect what distinguishes these from other "Unspecified"
Associations on basic.qea that DO render arrows correctly.
Possibilities:
  - The connector's sourcecard/destcard (multiplicity)
  - The connector's sourceaccess/destaccess
  - The presence of a Name vs anonymous
  - The t_diagramlinks geometry (Path=, SX/SY/EX/EY)

## Related

basic.qea path over-render (+6) is the mirror image — same 6
markers counted as paths instead of polygons. Closing one closes
the other.

