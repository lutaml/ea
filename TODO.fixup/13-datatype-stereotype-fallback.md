# 13 - DataType Stereotype Fallback for Klass

## Status: DONE (2026-07-25)

## Outcome

`Element::HeaderLines#for` now always emits a stereotype label as
the first header line. When the classifier has no explicit
stereotype_refs, falls back to a type-derived label:

- `Ea::Model::Klass` → `«DataType»`
- `Ea::Model::Enumeration` → `«enumeration»`
- `Ea::Model::DataType` → `«DataType»`
- `Ea::Model::PrimitiveType` → `«primitive»`
- `Ea::Model::Interface` → `«interface»`

For abstract Klasses the abstract name (`_Name`) is still italic;
for concrete Klasses the name is bold.

## Outcome metrics

Mean text abs diff across 185 diagrams: **14 → 7** (50% reduction).
CityFurniture text count: 30 → **34** (exact match).
Waterway text count: 103 → **111** (ref=113, within 2).

## Files changed

- `lib/ea/svg/ea_emitter/element/header_lines.rb` — fallback rule
