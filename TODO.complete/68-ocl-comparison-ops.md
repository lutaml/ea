# TODO.complete/68: OCL comparison operators

## Status: done

`Ea::Ocl` evaluates all comparison operators: `>`, `<`, `>=`, `<=`,
`=`, `==`, `!=`. Non-numeric operands raise `UnsupportedError`.

## Implementation

- `Nodes::Comparison` — `left op right` AST node.
- `Parser#split_on_comparison_op` handles all 7 operators with
  correct precedence (multi-char ops like `>=` checked before `>`).
- `Evaluator#eval_comparison` dispatches on `ast.op`, enforces
  `Numeric` operands.

## Acceptance

- `inv: self.age >= 18` parses + evaluates.
- `inv: self.count < self.max` parses + evaluates.
- `inv: self.x = self.y` evaluates as equality.
- `inv: self.x != self.y` evaluates as inequality.
- Non-numeric comparison raises `UnsupportedError`.

All specified in `spec/ea/ocl/ocl_spec.rb` (3 examples, 6 assertions).
