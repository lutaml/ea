# 04 - Annotations and Tagged Values (the EA value-add)

## Status: DONE (2026-07-19, folded into TODO 01)

## Problem

Pure-UML pipelines drop or downplay the EA value-add: rich
annotations (notes, documentation, change history) and tagged
values (key/value metadata scoped to stereotypes). The canonical
`Ea::Model` must capture these as first-class concepts.

## Approach

Modeled in TODO 01 as:

- `Ea::Model::Annotation` — `type` (enum: comment/documentation/
  change/file/requirement), `body`, `author`, `modified_date`
- `Ea::Model::TaggedValue` — `key`, `value`, `stereotype_ref`
  (optional; nil for unscoped tagged values)
- `Ea::Model::Stereotype` — `name`, `qualified_name`, `profile`,
  plus its tagged-value schema (declared keys with type/default)

These types live alongside Classifiers/Properties in the model —
they're not afterthoughts. The QEA source adapter populates them
from `t_object.Note`, `t_objectproperties`, `t_objectconstraints`,
etc.

## Verification

- Spec: a Class with 3 annotations of different types round-trips
- Spec: a Class with 2 stereotypes, each with tagged values,
  round-trips
- Spec: search projection includes annotation bodies in search
  content
