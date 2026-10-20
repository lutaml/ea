# Disposable Windows legend font measurement

Never merge this diagnostic branch into a runtime branch. It replaces the existing
`frontend.yml` dispatch entry point only on the disposable branch. There are no
workflow inputs: `requirements.json` specifies the complete matrix.

Run `frontend.yml` with ref `diagnostics/issue-135-legend-font-h16`. The job installs
Windows Japanese supplemental fonts, compiles the probe, and uploads
`legend-gdi-h16-h17`. No font binaries are uploaded or downloaded by the probe.

The 144 measurements cover MS UI Gothic and Cambria, signed GDI character heights
-16/-17, regular/bold weights 400/700, charsets 1/128, eight individual strings and
one combined 196-codepoint sample. Independent strings include `漢字`, reversed
`例凡`, Japanese body text, and Latin controls. Height17 supplies the existing
measurement control; height16 is additional data, not an inferred native setting.

`GdiProbe.cs` is copied byte-for-byte from diagnostic revision
`4517d6eab27632d2f183dceec25a410d52c90748`, SHA256
`248b39338a6e27168390168998cf5e48ac4de7b764476f276aabe4f379698457`.
Requirements retain all codepoints from the prior run39276232219 and add the
independent control strings. Runtime source baseline is
`2b36f47c20253f088d4c3539642d926fde493621`.

The probe records GetCharWidth32W advances, ABC widths, full-string extents,
DrawText extents, requested and selected faces, glyph coverage, text metrics,
mapping mode and DPI. Font file hashes/versions and runner metadata accompany the
numbers. It fails on face substitution, missing MS UI Gothic coverage, non-96-DPI
execution or failed advance calls. Missing Cambria glyphs remain explicitly
reported: selected Cambria does not establish per-character fallback identity.

Local verification: copied C# hash/bytes and JSON matrix validated; workflow YAML
parsed. Native compilation/execution awaits Windows: this macOS host has neither
PowerShell nor a C# compiler. No Windows verdict is claimed before the run.

These measurements cannot alone identify the original EA export host's fallback
face, binary/version or selected heading logical height. Matching the repeated
native `凡例` width is insufficient to establish that source contract.
