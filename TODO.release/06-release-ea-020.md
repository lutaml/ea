# 06 — Release ea 0.2.0

**Status: PENDING (depends on 04, 05)**

## Problem
ea is at 0.1.6. The gemspec pin change (`~> 0.2.0` → `~> 0.3`) is a
breaking change for anyone using ea's dev dependency — they need to
install lutaml-uml 0.3.0. This warrants a minor version bump.

## Steps
1. After TODO 04 and 05 are merged.
2. Bump version: `0.1.6` → `0.2.0`.
3. Verify `bundle exec rspec` passes in rubygems mode (CI mode).
4. Push + merge.
5. Trigger GHA release.

## Verification
- ea 0.2.0 on rubygems.
- `gem install ea && ea spa model.qea` works with published lutaml-uml 0.3.0.
- CI passes WITHOUT admin override (first time ever).
