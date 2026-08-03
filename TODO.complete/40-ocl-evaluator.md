# TODO.complete/40: OCL constraint evaluator

## Status: open

`Ea::Qea::Models::EaObjectConstraint` carries OCL expressions like
`inv: self.string->exists(o | o.matches('[a-zA-Z0-9]+'))`. We parse
the constraint text but never evaluate it.

## Plan

1. `Ea::Ocl::Parser` — parses a subset of OCL invariant syntax.
2. `Ea::Ocl::Evaluator` — walks the AST against an instance's
   attribute values, returns true/false.
3. Supported constructs (initial subset):
   - `inv: <expr>`
   - `self.<attr>` — attribute access
   - `<collection>->exists(x | <pred>)` — existential
   - `<collection>->forAll(x | <pred>)` — universal
   - `<string>.matches('<regex>')` — regex match
   - Boolean `and`, `or`, `not`
4. Wire into `ea validate` so OCL failures appear as warnings.

## OCP

- New OCL construct = new AST node + evaluator case.
- Parser and evaluator are separate (MECE).

## Acceptance

- Spec: parse + eval a known invariant from test.qea returns true/false.
- Spec: unknown construct raises `Ea::Ocl::UnsupportedError`.
