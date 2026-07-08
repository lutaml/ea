# 03 — Release lutaml 0.11.0

**Status: PENDING (depends on 02)**

## Problem
Published 0.10.19 has phantom runtime deps (htmlentities, liquid,
listen, nokogiri, paint, lutaml-path) that shouldn't be in the
meta-gem gemspec. Plus the 6 broken requires from TODO 02.

## Steps
1. After TODO 02 fix is merged.
2. Bump version: `0.10.19` → `0.11.0`.
3. Verify `require "lutaml"` works without LoadError.
4. Push + merge.
5. Trigger GHA release.

## Verification
- `require "lutaml"` succeeds.
- No LoadError from missing requires.
- Published gemspec deps are clean.
