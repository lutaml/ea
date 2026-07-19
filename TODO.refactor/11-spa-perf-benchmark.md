# 11 - SPA Performance Benchmark

## Status: DEFERRED (until pipeline is stable)

## Problem

Need empirical proof that the 45 MB CityGML QEA becomes
browseable.

## Approach

Benchmark spec that:
- Loads `plateau-model/20251010_current_plateau_v5.1.qea` (6 MB)
- Loads `plateau-model/20260323_CityGML_3.0_Consolidated_Draft.qea`
  (45 MB)
- Reports: parse time, model build time, projection time, output
  size, shard count
- Snapshot to compare regressions

## Verification

The plateau v5.1 must complete in < 60 s end-to-end on a laptop.
CityGML 45 MB should complete in < 10 min.
