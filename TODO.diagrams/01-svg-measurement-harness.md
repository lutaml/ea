# TODO-D 01 - SVG measurement harness

## Status: COMPLETE (2026-07-26)

## What was built

`spec/support/parity/checker.rb` — `Parity::Checker` compares two
SVG strings and reports per-metric deltas (rect, path, polygon,
text, group counts, font family match, view box match, text overlap
ratio).

`spec/support/parity/suite.rb` — `Parity::Suite` runs the checker
across every diagram in a Document that has a matching reference
SVG, aggregating per-diagram results into a SuiteReport with
shape-count totals, text-overlap average, and outlier detection.

## Why spec/support/ not lib/

These are test-only utilities — they exist to verify our emitter
against reference SVGs and have no production purpose. Keeping them
out of lib/ preserves the production/test boundary.

## Usage

```ruby
require "parity/suite"
suite = Parity::Suite.new(document, ref_dir).measure
suite.aggregate_shape_counts  # => { ours: {...}, reference: {...} }
suite.text_overlap_avg        # => 0.62
suite.outliers                # => [DiagramReport, ...]
```
