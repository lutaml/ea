# Windows GDI diagnostic

Diagnostic branch only. Never merge this workflow into product branches.
Dispatch `frontend.yml` at this branch; the existing dispatchable workflow path
allows GitHub to run the branch version without changing default-branch CI.

The artifact contains only measured numbers, corpus, font metadata and hashes.
Carlito binaries are downloaded from pinned OFL Google Fonts sources to runner
temporary storage, registered privately, and removed. No font binaries are uploaded.

`targets.json` preserves every input row and measures its exact height and weight
across candidate faces. `glyphs.json` measures unique codepoints for the requested
calibration configurations. Check actual face and missing-glyph flags before using
widths. Selected base-face identity does not identify each linked fallback glyph.
Real versus synthesized bold remains unresolved; tmWeight alone cannot prove it.

The Windows job compiles the helper, checks Arial at 96 DPI, installs Japanese
supplemental fonts, and measures the corpus. A complete artifact has manifest.json.
