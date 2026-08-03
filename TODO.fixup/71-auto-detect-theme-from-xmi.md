# 71 - Auto-Detect Theme from QEA StyleEx via XMI

## Status: COMPLETE (2026-07-26)

## What changed

`lib/ea/sources/xmi/diagram_builder.rb` — `build_one` now reads
`ext_diagram.style2.value` and assigns it to the Diagram's
`style_ex` attribute. EA stores StyleEx in the XMI's `<style2>`
element (alongside Style1 in `<style1>`). The value carries
`Theme=:119`, `SuppressFOC=1`, `AttPkg=1`, etc. — the same shape
the Diagram model already parses via `style_ex_flags` and
`display_config`.

This means: diagrams from sample XMI files now auto-resolve Theme
:119 (Carlito 7pt) without any manual theme setting.

## What was wrong before

The Xmi adapter was dropping `style2` entirely, so `style_ex` was
always nil. The Theme system worked correctly given a StyleEx
string — there was just no code path populating StyleEx from XMI.

## Acceptance

- simple.xmi "Package Contents" auto-detects Carlito 7pt without
  any manual intervention (previously emitted Calibri 13px).
- New spec asserts that `diagram.style_ex` includes "Theme=:119"
  and `diagram.theme.font_family` equals "Carlito".
- All 2286 specs pass.

## Why Option A from the original TODO was wrong

The original TODO assumed XMI omitted StyleEx and proposed
heuristic detection from element styles. In reality, XMI DOES
carry StyleEx via the style2 element — the previous Xmi adapter
was simply dropping it.
