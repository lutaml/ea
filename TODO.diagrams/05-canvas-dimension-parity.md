# TODO-D 05 - Canvas dimension parity

## Status: PARTIAL (2026-07-26)

## Current state

| | Avg delta | Range |
|---|---|---|
| Width | +87px | -403 to +1482 |
| Height | +576px | -109 to +4833 |

For diagrams where XMI matches reference content (small delta),
the canvas is consistently ~20-25 px wider and ~7-15 px taller
than reference. That delta is the frame margin.

## Frame margin rule

Reference SVGs use non-uniform frame margins around element
bounds:

- Left:   35 px (body left to canvas left)
- Right:  50 px (body right to canvas right)
- Top:    60 px (body top to canvas top)
- Bottom: 36 px (body bottom to canvas bottom)

These come from EA's frame outer border (6 px from canvas edge)
plus an additional 29/44/54/30 px inset for the body. The asymmetry
exists because:

- Top: extra space for the frame tab label (extends from y=6 to
  y=26 plus padding to body_top=60).
- Right/bottom: extra space for shadow / image padding.

## Fix attempted

`BoundsCalculator#compute` already reserves 20 px above each
Package element for the tab polygon. Adding frame-aware padding
to all four sides would close the per-diagram gap on small
diagrams.

## Why deferred

The 576 px average height delta dwarfs the frame margin issue.
Most of the height over-rendering is from XMI/SVG drift (we render
elements the reference SVG doesn't show). Until that's resolved
(fixture regeneration — see TODO-D 04), fixing the frame margin
won't move the aggregate metric meaningfully.

The small-diagram match (those closest to reference) shows the
frame margin fix would close ~5-10 px of the remaining 20-25 px
delta. Not enough to justify the added complexity right now.
