# 33 - normalize_lower was identity — fold into Cardinality module

## Status: DONE (2026-07-01, folded into TODO 27)

## Problem
`Transformer#normalize_lower` (transformer.rb:474-476) was:

```ruby
def normalize_lower(raw)
  raw.to_s
```

Pure identity — does nothing. Either remove it (callers can `.to_s`
themselves) or implement actual normalisation matching how
`normalize_upper` handles the `*` token.

## Fix
Folded into the Cardinality extraction (TODO 27). The new
`Cardinality.normalize_lower` returns the default `"0"` for empty
input, matching how real Sparx XMI represents unspecified lower
bounds (always emits `<lowerValue value="0"/>`, never empty).

This change also supports TODO 26 (upperValue/lowerValue count gap)
— always emitting `lowerValue` requires a sane default for the
"no bound specified" case.

## Verification
- Old `normalize_lower` identity removed from transformer.
- `Cardinality.normalize_lower("")` returns `"0"`.
- `Cardinality.normalize_lower("1")` returns `"1"`.
