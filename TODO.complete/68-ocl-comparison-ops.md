# TODO.complete/68: OCL comparison operators

## Status: open

`Ea::Ocl` supports `=`/`==` via equality, but not ordering: `>`,
`<`, `>=`, `<=`. These appear in real OCL invariants.

## Plan

1. Add `Comparison` AST node: `left op right` where op is one of
   `>`, `<`, `>=`, `<=`.
2. Parser recognizes the operators.
3. Evaluator compares numeric operands; raises `UnsupportedError` on
   non-numeric.

## Acceptance

- Spec: `inv: self.age >= 18` parses + evaluates (true / false).
- Spec: `inv: self.count < self.max` parses + evaluates.
