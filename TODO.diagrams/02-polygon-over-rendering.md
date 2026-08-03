# TODO-D 02 - Polygon over-rendering

## Status: COMPLETE (2026-07-26)

## Root cause

Two bugs caused polygon over-rendering:

1. **Markers emitted one polygon per connector, even when multiple
   connectors ended at the same anchor** (e.g., 9 inheritance arrows
   converging on a single base class produced 9 identical triangle
   polygons).

2. **Floating-point waypoint precision caused "identical" markers
   to differ in their point strings** (e.g., `683.37 2041.37` vs
   `683.39 2043.35`), defeating naive `body.uniq` deduplication.

## Fix

`Markers#layers` now deduplicates by **rounded anchor point** —
the first coordinate pair of each polygon/path, rounded to integer.
Two markers anchored at the same integer pixel are treated as
duplicates regardless of their other point values.

## Impact (full plateau measurement)

| Metric | Before | After |
|---|---|---|
| Polygon delta vs ref | +442 (46% over) | -10 (parity) |
