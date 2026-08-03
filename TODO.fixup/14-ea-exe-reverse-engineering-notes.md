# 14 - EA.exe Reverse-Engineering Notes

## Status: DONE (informational)

## Location

EA.exe and supporting DLLs are installed at:

    ~/Library/Application Support/CrossOver/Bottles/Enterprise Architect 16.x/drive_c/Program Files/Sparx Systems/EA/

Key files:
- `EA.exe` — main PE32 Windows binary, ~? MB
- `DrawEx161-32.dll` — drawing extension (CDrawEx class with
  Bezier/FillPath/StrokePath/etc.)
- `SSXML161-32.dll` — XML processing
- `EALayout161-32.dll` — layout engine
- `Cairo161-32.dll` — Cairo graphics bindings
- `Scintilla161-32.dll` — code editor

## What's discoverable

Symbols found in EA.exe (via `strings`):

- `SVGRenderer.cpp` — the C++ source file implementing SVG output
- `CBCGPSVG*` — BCGSoft SVG library classes (Base, Rect, Ellipse,
  Line, Text, Polygon, Path, Group, ClipPath, Gradient, Mask,
  ViewBox, Symbol, Marker)

The BCGSoft library is a commercial MFC extension. EA's SVG output
is built on top of `CBCGPSVG` and `CDrawEx` (a custom drawing
abstraction with both GDI and SVG backends).

## What's NOT discoverable without disassembly

- Exact style string assembly logic
- Coordinate transformation math
- Style bucketing rules (which paths share a `<g>`)
- Marker shape selection per relationship kind

These are constructed dynamically from many small format strings
at runtime. EA's diagram SVG output uses `printf`-style formatting
with the format templates assembled by C++ code from many
fragments — not stored as literal strings in the binary.

## Implication for parity work

Without source code or disassembly tools (Ghidra, IDA Pro), the
only practical path to closing remaining parity gaps is:

1. Empirically derive rules from reference SVGs (current approach)
2. Test against many diagrams to find consistent patterns
3. Accept residual ~5-10% diff as uncloseable without binary RE

The `Ea::Svg::ParityChecker` (fixup 08) is the right tool for
empirical validation — it surfaces exactly which dimensions
diverge so we can target them.
