# 75 - Visibility legend icons

## Status: WONTFIX (2026-07-26)

## Original hypothesis

101 plateau diagrams were missing 3-4 small 17×17 rects per
diagram. Originally believed to be auto-generated visibility toggle
icons that EA emits as a column of color swatches.

## Investigation finding

The 17×17 rects are actually manually-authored Note element content
(legend color swatches), not auto-generated UI elements. The Note
element's body text describes what each color represents (e.g.,
"GML classes", "CityGML classes"). Implementing this generically
would require parsing Note element intent, which is diagram-specific.

## Resolution

Closed as wontfix. The Note element rendering (TODO 78) handles the
container; the legend swatches inside are user-authored content
that flows from the Note body via future layout work.
