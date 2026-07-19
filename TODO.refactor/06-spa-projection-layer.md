# 06 - SPA Projection Layer

## Status: DONE (2026-07-19)

## Problem

The SPA needs a view of the model that's shardable, searchable,
and lazy-loadable. But sharding/search/lazy-loading are properties
of the *view*, not the model — putting them on `Ea::Model::*`
would couple the model to one consumer.

## Approach

`Ea::Spa::*` is the projection. One-way transform from
`Ea::Model::Document` to view-shaped artifacts:

- `Ea::Spa::Projector` — walks the model, emits:
  - `Skeleton` — top-level: metadata + package tree + flat
    classifier index (`id, name, type, package_id, qualified_name`)
  - `Shard` (per-entity) — full detail of one Class/Package/etc.
    including properties/operations/relationships/annotations/
    tagged values
  - `SearchIndex` — flat search entries (id, type, name, qname,
    package, content) ready for MiniSearch
  - `PackageTree` — hierarchical navigation tree

Projection is lossy by design: the SPA doesn't carry every model
field; it carries what browsing needs.

## Files

- `lib/ea/spa.rb` — namespace
- `lib/ea/spa/projector.rb`
- `lib/ea/spa/skeleton.rb`, `skeleton_entry.rb`
- `lib/ea/spa/shard.rb`, `shard_writer.rb`
- `lib/ea/spa/search_index.rb`, `search_entry.rb`
- `lib/ea/spa/package_tree.rb`, `package_tree_node.rb`
- `lib/ea/spa/lazy_ref.rb`
- `spec/ea/spa/*_spec.rb`

## Verification

- Projector spec: in-memory model → skeleton/shards/search
- Round-trip: QEA fixture → Model → Spa::Skeleton — assert
  element counts match
