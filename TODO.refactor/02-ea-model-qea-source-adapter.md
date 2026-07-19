# 02 - QEA Source Adapter

## Status: DONE (2026-07-19)

## Problem

`Ea::Qea::Database` is a typed wrap of the Sparx SQLite schema. It
mirrors the schema 1:1 — `t_object`, `t_package`, `t_connector`,
`t_attribute`, `t_operation`, `t_diagram`, `t_diagramlinks`,
`t_objectproperties`, `t_objectconstrains`, etc. — with their
packed-string columns and integer-coded types. It is intentionally
faithful to the source format.

`Ea::Model::*` is the canonical domain. Something has to translate.

## Approach

`Ea::Sources::Qea::Adapter` is a driving adapter: takes a
`Ea::Qea::Database`, produces an `Ea::Model::Document`. The adapter
walks the database tables once, builds typed model instances, and
resolves foreign-key references into model-id references.

The adapter is structured as a coordinator + per-table builders
(OCP/MECE):
- `Adapter` — orchestrates traversal
- `PackageBuilder` — `t_package → Model::Package`
- `ClassifierBuilder` — `t_object (Class/DataType/Enum/Interface)
  → Model::Classifier subclass`
- `PropertyBuilder` — `t_attribute → Model::Property`
- `OperationBuilder` — `t_operation + t_operationsparams →
  Model::Operation`
- `RelationshipBuilder` — `t_connector → Model::Relationship
  subclass` (dispatches on `Connector_Type`)
- `StereotypeBuilder` — `t_object + stylename → Model::Stereotype
  application`
- `TaggedValueBuilder` — `t_objectproperties → Model::TaggedValue`
- `AnnotationBuilder` — `t_object.Note + t_document →
  Model::Annotation`
- `DiagramBuilder` — `t_diagram + t_diagramlinks + t_dg +
  t_connector → Model::Diagram` (with coordinates!)

ID normalization: EA GUIDs (`{GUID}`) are normalized to plain
strings. References become model `id` references (decoupled from
source format).

## Files

- `lib/ea/sources.rb` — namespace
- `lib/ea/sources/qea.rb` — namespace + autoloads
- `lib/ea/sources/qea/adapter.rb`
- `lib/ea/sources/qea/*.rb` — per-table builders
- `spec/ea/sources/qea/*_spec.rb`

## Verification

- Builder specs against in-memory `Ea::Qea` fixtures
- Round-trip: real QEA fixture → `Ea::Model::Document`, assert
  package/class/relationship counts and known element names
