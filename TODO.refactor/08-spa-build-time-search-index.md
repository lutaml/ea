# 08 - Build-time Search Index

## Status: DONE (2026-07-19)

## Problem

Frontend search currently scans a flat list in memory. For 10k+
classes, that's slow. Need a real inverted index built at build
time, lazy-loaded at run time.

## Approach

`Ea::Spa::SearchIndex` produces documents in MiniSearch-friendly
shape (id, name, qualifiedName, type, package, content with
boosts). Frontend loads MiniSearch JS lib lazily on first search
focus,hydrates the index from `search.json`.

Frontend integration deferred until TODO 09 lands the data
contract. Ruby-side emission: implemented in TODO 06.

## Verification

- Spec: search index includes all classifiers with correct boosts
- Spec: search content includes annotation bodies (rich)
