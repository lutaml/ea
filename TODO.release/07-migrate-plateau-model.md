# 07 — Migrate plateau-model to ea gem

**Status: PENDING (depends on 06)**

## Problem
The plateau-model project (`/Users/mulgogi/src/mn/plateau-model`)
currently depends on the broken `lutaml` meta-gem via a local path:

```ruby
# Gemfile
gem "lutaml", path: "/Users/mulgogi/src/lutaml/lutaml"
```

And generates SPA via:
```bash
bundle exec lutaml uml build-spa model.qea -o index.html
```

## Fix
Switch to the standalone `ea` gem:

```ruby
# Gemfile
source "https://rubygems.org"
gem "ea", "~> 0.2"
```

```bash
bundle exec ea spa model.qea -o index.html
```

## Verification
- Generated index.html is structurally equivalent to the existing one
  (same packages=58, diagrams=188, classes≈600).
- No dependency on the lutaml meta-gem.
