# 09 - SPA Frontend Data Contract

## Status: DEFERRED (frontend extraction)

## Problem

Vue frontend lives in `lutaml-uml/frontend`. EA-side SPA needs to
share it without forking.

## Approach

Define a versioned JSON schema for the SPA data contract. Both
`lutaml-uml`'s SPA and `Ea::Spa` produce JSON conforming to the
schema. Frontend is extracted to its own npm package
(`@lutaml/spa-frontend`) and consumed by both.

Deferred until Ruby-side projection is proven stable. For now,
`Ea::Spa` emits JSON in a shape compatible with the existing Vue
frontend's data loader, so we can copy the frontend in for
testing.

## Verification

- Schema spec: every field documented, has a fixture
- Cross-compat: existing Vue frontend can load `Ea::Spa`'s output
