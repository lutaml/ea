# 13 - DRY: Extract Duplicated Transformation Methods

## Status: ✅ DONE

## What was verified
Shared utility methods are already in `BaseParser`:
- `add_info(message, context = {})` — line 288
- `format_file_size(size)` — line 297
- `format_statistics(stats)` — line 310

`QeaParser` and `XmiParser` do NOT have their own copies.

`constantize_class` duplication was consolidated: `TransformationEngine` now
calls `Transformations.constantize` directly (removed the duplicate wrapper).
`FormatRegistry#constantize_parser_class` delegates to the same method.

Single source of truth: `Ea::Transformations.constantize`.
