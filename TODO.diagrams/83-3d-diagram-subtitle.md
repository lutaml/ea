# TODO-D 83: 3D diagram subtitle over-render (3 phantom subtitles)

## Status: open

The "3D都市モデル応用スキーマと他のスキーマとの関係" diagram
shows 4 placed packages:

  - Inner "3D都市モデル" (parent: outer "3D都市モデル")
  - i-UR (parent: Conceptual Models)
  - CityGML2.0 (parent: Conceptual Models)
  - gml (parent: Conceptual Models)

EA reference renders 0 "(from X)" subtitles. Our code renders
3 (the inner 3D都市モデル was suppressed by the name-match rule
in commit cf3dcf2; the other 3 still over-render).

## Compared to udx

udx diagram shows 3 placed packages:

  - 都市計画データ (parent: 3D都市モデル)
  - i-UR (parent: Conceptual Models)
  - CityGML2.0 (parent: Conceptual Models)

EA reference renders 3 subtitles. So udx and 3D have similar
structure but opposite subtitle behavior.

## What differs

The diagrams have similar PDATA/StyleEx (both Package type,
HideParents=0). The ONLY visible difference: 3D includes a
placed element (inner 3D都市モデル) whose parent shares its name
with itself.

## Hypothesis (untested)

When ANY placed package has a parent whose name collides with
another package's name in the diagram, EA suppresses all
subtitle rendering for that diagram. The reasoning: name
collisions confuse subtitle interpretation, so safer to omit.

Alternatively: a flag in t_diagram or t_diagramobjects that
we're not yet parsing.

## Investigation block

This rule cannot be safely derived from one example. Closing
this gap requires either:
1. Finding the rule from additional EA reference outputs (with
   different package-name configurations).
2. Reverse-engineering EA's source code for the subtitle logic.
3. Per-diagram manual tuning (not scalable).

## Related

  - TODO-D 75: plateau text under-render (-36 / -37 after this
    fix). The 3D diagram contributes +3 (or +4 pre-fix) to the
    text count discrepancy.
