# 38 - XMI parser feature parity with QEA

## Status: DONE (2026-07-07)

## Problem
The XMI parser produced a meaningfully smaller `Lutaml::Uml::Document`
than the QEA parser for the same model:

| Capability        | QEA                  | XMI (was)          | XMI (now)        |
|-------------------|----------------------|--------------------|------------------|
| Packages          | 42                   | 42                 | 42               |
| Classes           | 65 (incl. components)| 30                 | 30 + signals/components/instances handled |
| Associations      | 45                   | 0                  | 40+ (package-level + per-class) |
| Diagrams          | 22                   | 0 at document root | 22 (aggregated)  |
| InstanceSpecification | 12 (as instances) | 0                  | 12 (as instances)|

Three concrete bugs:

1. `build_classes` only selected `uml:Class`, `uml:AssociationClass`,
   `uml:Interface`. Missed `uml:InstanceSpecification`, `uml:Signal`,
   `uml:Component`. The 12 InstanceSpecifications in basic.xmi were
   silently dropped.
2. `build_document` populated only `doc.packages`. Never set
   `doc.diagrams` or `doc.associations`. Even though per-package
   `build_diagrams` worked, the document-level collection stayed empty.
3. `uml:Association` packagedElements at the package level were never
   transformed. basic.xmi has 40 such elements; the parser produced 0
   document-level associations.

## Fix

### New: `build_instances(package)` method
Mirrors the QEA factory's `InstanceTransformer`. Walks packagedElements
of type `uml:InstanceSpecification`, builds `Lutaml::Uml::Instance`
objects with name, xmi_id, classifier (resolved via id_name_mapping),
definition. Populates `package.instances`.

### Updated: `build_classes(package)`
Adds `uml:Signal` and `uml:Component` to the type filter. These are
classifiers semantically equivalent to `uml:Class` for UML Document
purposes.

### New: `aggregate_document_extensions(doc)` method
Called once at the end of `build_document`. Walks the document tree
and populates:
- `doc.diagrams` — concatenation of all per-package diagrams
- `doc.associations` — concatenation of (a) per-class associations and
  (b) package-level `uml:Association` packagedElements

### New: `build_package_associations(package)` method
Selects `uml:Association` packagedElements directly under a package.
Each becomes a `Lutaml::Uml::Association` with owner_end / member_end
resolved from the `<memberEnd>` children's `idref` attributes.

## Verification
- `Ea::Transformations.parse("spec/fixtures/basic.xmi")` now returns:
  - 22 diagrams at document level (was 0)
  - 40+ associations at document level (was 0)
  - 12 instances across packages (was 0)
- Round-trip parity: same fixture parsed via QEA and XMI produces
  equivalent document-level collections (within known XMI modeling
  differences — e.g. XMI doesn't carry t_connector cardinality the
  same way QEA does).
- New parity spec in `spec/ea/xmi/parser_spec.rb` asserts the
  document-level counts for basic.xmi.

## Architecture notes
- `aggregate_document_extensions` is a single post-build walk — O(N)
  over the package tree.
- `build_package_associations` mirrors the QEA factory's
  AssociationBuilder pattern: package-level relationships live on the
  document, class-level relationships live on the class.
- No changes to the existing `build_associations(xmi_id)` per-class
  walk — backward compatible with consumers that read
  `class.associations`.
