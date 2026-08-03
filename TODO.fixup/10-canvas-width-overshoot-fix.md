# 10 - Canvas Width Overshoot Fix

## Status: DONE (2026-07-24)

## Outcome

`Canvas.from` now uses **logical bounds for x-extent** (matching
EA's canvas left/right exactly) while still unioning **logical +
image_bounds for y-extent** (image_bounds extends below bounds
for shadow/padding).

Waterway width: 1163 → **1138** (matches ref exactly).
Waterway height: 899 (ref=892, within 7).
Building width: 1381 (ref=1406, within 25).
Bridge width: 1292 (ref=1305, within 13).

## Files changed

- `lib/ea/svg/ea_emitter/canvas.rb` — split x/y source rules
- `spec/ea/svg/ea_emitter/canvas_spec.rb` — unchanged, still passes
