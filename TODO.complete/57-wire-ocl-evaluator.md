# TODO.complete/57: Wire OCL evaluator into `ea validate`

## Status: done

`Ea::Ocl::Parser` + `Evaluator` exist with full specs but no
production caller. `ea validate` runs structural validators only;
OCL constraints stored in `t_objectconstraint` are never evaluated.

## Plan

1. Add `Ea::Qea::Validation::OclConstraintValidator` that walks
   `database.collections[:object_constraints]`, parses each
   constraint's OCL expression, and evaluates it against the
   owning object's attribute values.
2. Register in `ValidationEngine`.
3. Failures surface as validation messages with severity = :warning
   (OCL failures aren't structural errors).

## Acceptance

- Spec: a constraint like `inv: self.name.matches('[A-Z]+')`
  applied to an object with `name = "foo"` produces a warning.
- Spec: evaluator returns true for a passing constraint.
