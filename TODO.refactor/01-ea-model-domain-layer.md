# 01 - Ea::Model Domain Layer

## Status: DONE (2026-07-19)

## Problem

EA QEA/XMI sources are tightly coupled to their storage format. The
existing pipeline funnels everything through `Lutaml::Uml::Document`,
which is lossy (drops annotations, tagged values, diagram coordinates)
and slow (allocates huge Ruby object graphs).

We need a canonical in-process domain model — `Ea::Model::*` — that
both QEA and XMI sources harmonize into. The model is the single
source of truth for "what the model IS". Source format becomes
irrelevant once you're in `Ea::Model`.

## Architectural Principle

Hexagonal / Ports & Adapters. `Ea::Model` is the hexagon:
- **Driving ports** = source adapters (`Ea::Sources::Qea`,
  `Ea::Sources::Xmi`) that produce model instances from source files.
- **Driven ports** = consumer adapters (`Ea::Spa`, future
  `Ea::Export::*`, `Ea::Validate::*`, `Ea::Compare::*`) that project
  or transform the model for their use case.

Dependencies point inward only. The model never knows about a source
format; consumers never know about a source format.

## Domain Types

- `Ea::Model::Document` — root container (packages, classifiers,
  relationships, diagrams, stereotypes)
- `Ea::Model::Package` — hierarchical containment (sub-packages,
  owned classifiers)
- `Ea::Model::Classifier` (abstract) → `Class`, `DataType`,
  `PrimitiveType`, `Enumeration`, `Interface`
- `Ea::Model::Property` — typed slot, multiplicity, defaults,
  stereotypes, tagged values
- `Ea::Model::Operation` — signature, parameters, return type
- `Ea::Model::Parameter`
- `Ea::Model::Relationship` (abstract) → `Association` (two ends),
  `Generalization`, `Realization`, `Dependency`
- `Ea::Model::EnumerationLiteral`
- `Ea::Model::Stereotype` — first-class, with tagged-value schema
- `Ea::Model::TaggedValue` — first-class (key, value, scope)
- `Ea::Model::Annotation` — first-class (type, body, author)
- `Ea::Model::Diagram` + `DiagramElement` (with bounds/style) +
  `DiagramConnector` (with waypoints/style)
- `Ea::Model::Point` (x,y), `Ea::Model::Bounds` (x,y,w,h),
  `Ea::Model::Waypoint`

## Files

- `lib/ea/model.rb` — namespace + autoloads
- `lib/ea/model/base.rb` — `Ea::Model::Base` (lutaml-model subclass,
  common `id`, `name`, `qualified_name` attrs)
- One file per type under `lib/ea/model/`
- `spec/ea/model/*_spec.rb` — type-level specs

## Verification

- Each type has a spec verifying attributes, defaults, JSON round-trip
- `Ea::Model::Document` builds in-memory fixtures for use by upstream
  specs (no source-format coupling in model specs)
