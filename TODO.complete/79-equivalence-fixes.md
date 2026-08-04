# TODO.complete/79: QEA→XMI equivalence fixes (namespace, defaults, aggregation)

## Status: done

Previous TODOs (66, 72, 78) closed count-parity gaps. But COUNT !=
EQUIVALENCE — element-by-element xmi:id comparison revealed deeper
structural issues. This TODO fixes the real equivalence problems.

## Investigation method

Built `/tmp/equivalence.rb` that parses both ours and EA's XMI,
extracts every element by `xmi:id`, then compares common IDs
element-name + attribute-by-attribute. Initial result:

```
Total IDs: ours=830 ref=777
Common: 409, Only ours: 421, Only ref: 368
Common IDs with mismatched content: 585 / 409
```

## Fixes applied

1. **Namespace version mismatch** — xmi gem uses `20131001`, EA uses
   `20110701`. Added `normalize_namespaces` post-processor that
   replaces the namespace URIs to match EA's version. Affects every
   element.

2. **Attribute verbosity** — we emitted UML defaults that EA omits:
   - `Visibility.from_scope(0)` now returns nil instead of "public"
   - `Visibility.boolean_from_flag("0")` now returns nil instead of false
   - `normalize_concurrency` returns nil for "Sequential" (default)
   - `normalize_direction` returns nil for "in" (parameter default)

3. **exporterID** — added `exporter_id: "1624"` to the xmi:Documentation
   element (EA's build ID).

4. **aggregation on ownedEnd** — was reading `sourcecontainment`/
   `destcontainment` (string field, always "Unspecified"). Now reads
   `sourceisaggregate`/`destisaggregate` (integer field: 0=none,
   1=shared, 2=composite). Matches EA's `aggregation="shared|composite"`.

## Result

Content mismatches among common IDs dropped from **585 → 237** (59%
reduction). Remaining mismatches are primarily:
- Synthesized ID ordering (our LI000001 maps to a different attribute
  than EA's LI000001 — counter assignment depends on traversal order)
- Some visibility="private" attributes where the QEA scope field
  differs from what EA emits

## Spec changes

Updated 8 specs that asserted the OLD behavior (defaults emitted,
wrong namespace version, aggregation absent). Now assert the
EA-equivalent behavior.

Full suite: 2203 examples, 0 failures, 55 pending.
