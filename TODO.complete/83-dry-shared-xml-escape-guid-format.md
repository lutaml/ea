# TODO.complete/83: DRY — shared XmlEscape + GuidFormat modules

## Status: done

Two cross-subsystem DRY violations extracted into shared top-level
modules.

## 1. Ea::XmlEscape

The XML entity escape (`& < > "` → entities) was duplicated in 4
files with subtle differences:

| File | Escapes | Nil-safe? |
|------|---------|-----------|
| `text_renderer.rb` | `& < > "` | no |
| `html_reporter.rb` | `& < > "` | yes |
| `shapescript/renderer.rb` | `& < >` (missing `"`!) | no |
| `extension_serializer.rb` | `& < > "` | no |

The ShapeScript version was **missing quote escaping** — a latent
bug that could produce broken SVG if a shape value contained `"`.

All four now call `Ea::XmlEscape.call(text)`:
- One canonical implementation
- Always escapes all 4 special chars
- Always nil-safe (via `to_s`)

Spec: `spec/ea/xml_escape_spec.rb` (8 examples).

## 2. Ea::GuidFormat

GUID→XMI ID conversion was duplicated in 3 subsystems:

| File | Operation |
|------|-----------|
| `Transformers::QeaToXmi::GuidFormat` | full conversion (canonical) |
| `Sources::Qea::IdNormalizer` | inline `gsub(/[{}]/,"")` + `.tr("-","_")` |
| `Qea::Factory::ReferenceResolver` | inline `gsub(/[{}]/,"").upcase` |

Promoted `GuidFormat` to top-level `Ea::GuidFormat` (shared).
`Transformers::QeaToXmi::GuidFormat` is now an alias (backward
compatible — existing references don't break).

Added `strip_braces` method for callers that need just the brace
removal without prefix/dash conversion. `IdNormalizer` and
`ReferenceResolver` now use it.

## Result

- Export output byte-identical (405898 bytes)
- 8 new specs (XmlEscape)
- 2211 examples, 0 failures, 55 pending
