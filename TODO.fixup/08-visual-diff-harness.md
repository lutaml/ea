# 08 - Visual Diff Regression Harness

## Status: DONE (2026-07-24)

## Outcome

New `Ea::Svg::ParityChecker` compares two SVG strings across seven
parity metrics: rect, path, polygon, text, group counts + font
family + view_box match.

Returns a `Report` Struct of `Diff` Structs. Specs can assert on
individual dimensions or use `report.any_within?(tolerance)` for
aggregate checks.

## Usage

```ruby
checker = Ea::Svg::ParityChecker.new(ours: our_svg, reference: ref_svg)
report = checker.report
expect(report.text.within?(5)).to be(true)
expect(report.font_family).to be(true)
```

## Files changed

- `lib/ea/svg/parity_checker.rb` — NEW checker with Report/Diff
- `lib/ea/svg.rb` — autoload registration
- `spec/ea/svg/parity_checker_spec.rb` — 8 specs
