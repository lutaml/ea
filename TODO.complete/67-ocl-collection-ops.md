# TODO.complete/67: OCL collection operations

## Status: open

`Ea::Ocl` evaluates a subset of OCL: `exists`, `forAll`, `matches`,
`and`/`or`/`not`, attribute access. Real EA constraints use
`size()` and `isEmpty()` (parity: 0/0 because the OCL evaluator
wasn't even invoked before this session).

## Plan

1. Add `CollectionSize` AST node: `<collection>->size()`.
2. Add `CollectionIsEmpty` AST node: `<collection>->isEmpty()`.
3. Parser recognizes `->size` and `->isEmpty` patterns.
4. Evaluator returns integer / boolean.

## Acceptance

- Spec: `inv: self.items->size() > 0` parses + evaluates.
- Spec: `inv: self.items->isEmpty() or self.required` parses + evaluates.
