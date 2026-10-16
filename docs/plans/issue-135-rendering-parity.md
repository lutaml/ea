# QEA rendering parity

The remaining work on issue 135 covers text content, typography, classifier
compartments, connector routes and label placement. Each change must reproduce a
published EA difference, retain relevant existing matches, and pass focused tests.

This batch restores classifier font inheritance and point units, uses the
Cambria compartment spacing for measured fonts, corrects header seats and default
attribute color, removes labels for undrawn connectors, and preserves fixed
multiplicity and ordering text. Association routing respects stored direction,
offsets and authored orthogonal bends.

Validation compares the same 220 available diagrams. The comparable text metric
retains its original 184 independently aligned diagrams; newly recovered
alignments are a separate population. Reference occurrences are consumed once,
without wider tolerances. Focused public-rendering regressions and preservation
controls accompany the rules. Required CI and final branch review precede merge.

Whole-issue acceptance remains open: unresolved route groups, broader label
clusters, text differences and unaligned diagrams stay visible in the acceptance
ledger. The original 260-diagram corpus is unavailable. This batch does not close
issue 135 or establish an aggregate completion percentage.
