# TODO-D 40: Standalone "1" multiplicity discriminator

## Problem

EA renders the "1" multiplicity at connector endpoints in SOME
diagrams but NOT others. In basic.qea's "Domain Model" diagram, EA
shows "1" at the dest end of two connectors. In plateau, most
connectors with explicit cardinality "1" do NOT show "1".

## Empirical Findings

| Change                           | Plateau | Basic |
|----------------------------------|---------|-------|
| Always render (no filter)        | -39     | -22   |
| Filter "1" from standalone mult  | -30     | -30   |
| Allow "1" from explicit "1" only | +89     | TBD   |

The "filter '1'" approach helps plateau (-9) but hurts basic (-8).
The "allow explicit '1'" approach hurts plateau (+128) more.

## Root Cause

The discriminator is NOT in t_connector.SourceCard/DestCard alone
(both basic and plateau have explicit "1" in some connectors).
It may be in:
- Per-diagram StyleEx flag (not yet identified)
- Per-connector StyleEx (similar to HideIcon)
- TConnectorNotation vs explicit navigability
- Connector SubType

## Acceptance

- Identify the discriminator that separates "Domain Model" (shows "1")
  from typical plateau connector (no "1" despite same cardinality).
- Implement in standalone_multiplicity in EndLabel.
- basic.qea Domain Model overlap 0.7 → ~0.9.
- basic.qea average 81.5% → ~85%.
- plateau text delta unchanged.
