# 49 - Render All Sample Diagrams Integration Test

## Status: DEFERRED

## Decision

The visual_regression_spec.rb already renders many diagrams
from the plateau XMI. Adding a new spec for examples/exports/*
would duplicate the test surface without adding new coverage
until QEA loader is wired (for style_ex).

Deferred until QEA wiring or when specific sample diagrams
need targeted testing.

## Files changed

None.
