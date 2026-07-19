# 07 - Sharded Output Strategy

## Status: DONE (2026-07-19)

## Problem

Single-file output doesn't scale. For large models, the SPA must
ship as skeleton + per-entity shards, loaded on demand.

## Approach

Output strategy pattern (mirrors existing lutaml-uml shape):

- `Ea::Spa::Output::Strategy` (abstract)
- `Ea::Spa::Output::SingleFileStrategy` — embeds everything in
  one HTML (small models only)
- `Ea::Spa::Output::ShardedMultiFileStrategy` — directory with
  `skeleton.json`, `search.json`, `data/classes/{id}.json`,
  `data/packages/{id}.json`, `data/diagrams/{id}.json`

Size threshold auto-selects: under 2 MB JSON → single file, else
sharded. Configurable.

## Verification

- Spec: small model → single-file output
- Spec: large model → sharded output, skeleton lists every
  classifier, each shard file exists and parses
