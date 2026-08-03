# TODO.complete/42: HTML diff report

## Status: done

Text diff is hard to scan in PR descriptions. HTML report with
color-coded added/removed/renamed rows is much more reviewable.

## Plan

1. `Ea::Diff::HtmlReporter` — consumes a Comparator's differences,
   emits an HTML table with green/red/yellow rows.
2. CLI: `ea diff OLD NEW --format=html -o report.html`.
3. Include summary stats (X added, Y removed, Z renamed).

## Acceptance

- Spec: HTML output contains `<table>` with one row per diff.
- Spec: added rows have class `added`, removed have `removed`.
