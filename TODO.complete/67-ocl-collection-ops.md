# TODO.complete/67: OCL collection operations

## Status: done

`Ea::Ocl` evaluates `->size()` and `->isEmpty()` collection
operations. Specified in `spec/ea/ocl/ocl_spec.rb` (4 examples).

## Implementation

- `Nodes::CollectionSize` — `<collection>->size()` AST node.
- `Nodes::CollectionIsEmpty` — `<collection>->isEmpty()` AST node.
- `Parser` recognizes `->size` and `->isEmpty` patterns via regex.
- `Evaluator#eval_size` returns integer; `#eval_is_empty` returns
  boolean. Both check `is_a?(Array)` (not `respond_to?`) per the
  typing rules.

## Acceptance

- `inv: self.items->size() > 0` parses + evaluates.
- `inv: self.items->isEmpty() or self.required` parses + evaluates.
