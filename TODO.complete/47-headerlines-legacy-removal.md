# TODO.complete/47: HeaderLines legacy module removal

## Status: done

`Ea::Svg::EaEmitter::Element::HeaderLines` still exists alongside
the new `HeaderLinePipeline`. After verifying the pipeline covers
all cases, the legacy module should be removed or aliased.

## Plan

1. Replace `Element::HeaderLines.for(...)` calls in elements.rb
   with `Element::HeaderLinePipeline.for(...)`.
2. Make `HeaderLines` a thin module-level alias to
   `HeaderLinePipeline` (backward compat).
3. Or delete entirely if no external callers.

## Acceptance

- `grep -rn "HeaderLines\." lib/` shows only the alias (or zero).
- All existing specs pass.
