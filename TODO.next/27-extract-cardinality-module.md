# 27 - Extract CardinalityParser module from Transformer

## Status: DONE (2026-07-01)

## Problem
`lib/ea/transformers/qea_to_xmi/transformer.rb` mixes five concerns
in one 503-line class:

- orchestration (build_root, build_model, build_extension)
- walk traversal (build_package, package_children, subpackages)
- element construction (build_class, build_attribute, ...)
- **cardinality parsing** (parse_cardinality, parse_range,
  normalize_bound, normalize_upper, normalize_lower, UNLIMITED_TOKENS)
- XML post-processing (strip_empty_elements)

Cardinality parsing is a pure-function concern with no dependency on
the transformer's state. It belongs in its own module so it can be
unit-tested in isolation and reused if other transformers need the
same logic (e.g., UmlToXmi, future LutamlToXmi).

## Fix
Extract a `Cardinality` module under
`lib/ea/transformers/qea_to_xmi/cardinality.rb`:

```ruby
module Ea::Transformers::QeaToXmi
  module Cardinality
    UNLIMITED_TOKENS = %w[* *-1 unbounded].freeze
    DEFAULT_UPPER = "-1"
    DEFAULT_LOWER = "0"

    module_function

    def parse(raw)
      return empty_bounds if raw.nil? || raw.to_s.empty?
      stripped = raw.to_s.strip
      return parse_range(stripped) if stripped.include?("..")
      single = normalize_bound(stripped)
      { lower: single, upper: single }
    end

    def normalize_upper(raw)
      UNLIMITED_TOKENS.include?(raw.to_s.strip.downcase) ? "-1" : raw.to_s
    end

    def normalize_lower(raw)
      raw = raw.to_s.strip
      raw.empty? ? DEFAULT_LOWER : raw
    end

    # ... private helpers
  end
end
```

The transformer imports it (`extend Cardinality` or call via
`Cardinality.parse(...)`). File size drops by ~40 lines; logic is
testable in isolation.

This change also resolves TODO 33 (`normalize_lower` was identity;
now it normalises empty → "0").

## Verification
- New `spec/ea/transformers/qea_to_xmi/cardinality_spec.rb` covers
  edge cases: `nil`, `""`, `"*"`, `"0..*"`, `"1..1"`, `"unbounded"`,
  malformed input.
- Transformer file drops below 470 LOC.
- All existing transformer specs continue to pass.
