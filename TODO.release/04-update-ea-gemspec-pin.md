# 04 — Update ea gemspec pin to ~> 0.3

**Status: PENDING (depends on 01)**

## Problem
ea.gemspec pins `spec.add_development_dependency "lutaml-uml", "~> 0.2.0"`.
This resolves to 0.2.12 on rubygems, which doesn't have UmlRepository.
CI fails on every PR.

## Fix
```ruby
# BEFORE:
spec.add_development_dependency "lutaml-uml", "~> 0.2.0"

# AFTER:
spec.add_development_dependency "lutaml-uml", "~> 0.3"
```

`~> 0.3` means `>= 0.3.0, < 1.0.0`, which resolves to 0.3.0 (with
UmlRepository) and excludes the incompatible 1.0.0.

## Verification
- `bundle exec rspec` passes in CI (rubygems mode) without admin override.
