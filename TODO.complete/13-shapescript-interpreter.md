# TODO.complete/13: Basic ShapeScript interpreter

## Status: deferred

EA's MDG technologies can define stereotype icons via ShapeScript — a
domain-specific language for vector shapes (lines, polygons, ellipses).

This is what closes the **polygon -4 parity gap** (TODO.diagrams/73): the
small stereotype decorator icons EA renders inside element bodies.

## Why deferred

- Full ShapeScript interpreter is high effort (~1-2 weeks).
- The gap is small (4 polygons across 188 diagrams).
- EA's InternalTechnologies encryption blocks the easy path to reference
  shape definitions (see TODO.diagrams/87).

## When to revisit

- Encryption is broken and we have plaintext shape definitions.
- A user specifically requests stereotype decorator icon rendering.
- A larger gap emerges that ShapeScript would close.

## Partial path (lower effort)

If we acquire plaintext shape definitions for a few high-value stereotypes
(FeatureType, Type), we can hardcode their polygons without a full
ShapeScript interpreter. This is a tactical compromise.
