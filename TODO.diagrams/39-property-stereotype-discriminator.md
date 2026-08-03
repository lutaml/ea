# TODO-D 39: «property» stereotype label discriminator

## Problem

EA renders the «property» stereotype between role name and
multiplicity for some association connectors but NOT others.
We currently always render it, causing basic.qea over-rendering
(~8 extra texts per diagram).

## Investigation

Tried **OY gap between LLT and LLB geometry boxes** as discriminator:

| Threshold | Plateau delta | Basic delta |
|-----------|---------------|-------------|
| Always (no filter) | -39 | -38 |
| Gap >= 15 | -392 (−353) | -46 (−8) |
| Gap >= 5 | -280 (−241) | -38 |
| Gap >= 1 | -188 (−149) | -30 (−8) |

The OY gap is NOT the correct discriminator. Many plateau connectors
with gap=0 still need «property», while basic connectors with gap=0
don't. Both sets have role names and multiplicities.

## Architecture

The structural predicate `EndLabel#property_label?` is already
extracted and wired. When the correct discriminator is found, it's
a one-line change to the predicate body.

## Acceptance

- Identify the field/flag in t_connector or t_diagramlinks that
  controls «property» rendering. Candidates:
    - t_connector.SubType
    - t_connector.StyleEx (per-connector)
    - LLT box CY value (content height)
    - TExplicitNavigability flag interaction
- Implement the check in property_label?
- Specs cover both rendering and non-rendering cases.
