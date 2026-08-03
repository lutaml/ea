# 79 - Operation compartment text rendering

## Status: ANALYZED (2026-07-26)

## Current state

`OperationRenderer` exists and emits operation signatures as text
lines. `Elements#groups_for` invokes it when the classifier has
operations AND `show_operations?` is true.

The Plateau parity failures showed large text over-rendering
(+68 on Tunnel diagram). Investigation revealed:

1. We render `«DataType»` stereotype labels for every classifier
   with a stereotype — ref SVGs only show stereotypes for some.
2. We render the `tags` compartment + tagged value lines for every
   classifier with tagged values — ref only shows them on 2/220
   diagrams.

Both are visibility rule gaps, not Operation-specific bugs. The
OperationRenderer itself works correctly when invoked.

## Why deferred

The actual rendering is correct; the gap is in WHEN to render.
Closing it requires understanding EA's stereotype-tagged-value
visibility rule (TODO 80).
