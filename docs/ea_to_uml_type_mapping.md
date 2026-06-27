# EA Object Type → UML Mapping

This document describes how `ea` maps Sparx EA object types (from the QEA
`t_object` table's `Object_Type` column) to UML model elements during the
`Ea::Qea.to_uml` transformation.

The mapping is implemented in
`Ea::Qea::Models::EaObject#transformer_type`, which returns a
`TransformerRegistry` key or `nil`.

## Principles

1. **Hub-and-spoke, not format-to-format.** Both QEA and XMI parse *into* a
   common `Lutaml::Uml::Document`. There is no direct QEA↔XMI translator.
2. **Model elements only.** Only EA object types that correspond to genuine
   UML model elements are transformed. Rendering hints and tool-internal
   plumbing are dropped.
3. **Stereotype can override type.** A Class with stereotype `enumeration`
   transforms as an Enum, not a Class.

## Mapping table

| EA `Object_Type`   | UML element         | Transformer key | Notes                                     |
|--------------------|---------------------|-----------------|-------------------------------------------|
| `Class`            | `UmlClass`          | `:class`        |                                           |
| `Interface`        | `UmlClass`          | `:class`        |                                           |
| `Enumeration`      | `Enum`              | `:enumeration`  | Also: Class with `<<enumeration>>`        |
| `DataType`         | `DataType`          | `:data_type`    |                                           |
| `Instance`/`Object`| `Instance`          | `:instance`     |                                           |
| `Package`          | `Package`           | `:package`      | From `t_package`, not `t_object`          |
| `Text`             | _(dropped)_         | `nil`           | See below                                 |
| `Note`             | _(dropped)_         | `nil`           | See below                                 |
| `ProxyConnector`   | _(dropped)_         | `nil`           | See below                                 |

Connectors (`t_connector`) are handled separately from objects and map to
`Association`, `Generalization`, or `Dependency` depending on their type.

## Dropped types — rationale

### `Text`

A free-form text box placed on a diagram for labeling or annotation. It is a
**rendering hint**, not a model element — it has no semantic relationship to
the classes and packages in the model.

- **Current behavior:** dropped. Content is not preserved in the UML document.
- **Why not `UmlClass`:** Text has no attributes, operations, or type
  semantics. Treating it as a class (the previous behavior) polluted the class
  collection with non-classes and broke class counts.
- **Future:** map to `Lutaml::Uml::Comment`. This requires adding a `comments`
  collection to `Lutaml::Uml::Package` (currently only `Document` has one, and
  it is a flat string list). Until then, Text content is lost.

### `Note`

A note element on a diagram. Same category as `Text` — a rendering/annotation
hint, not a model element.

- **Current behavior:** dropped.
- **Future:** same as `Text` — map to `Comment` when the metamodel supports it.

### `ProxyConnector`

EA's internal stub representing a connector that crosses a package boundary.
When a connector in package A points at an element in package B, EA may insert
a `ProxyConnector` in one package as a stand-in for the foreign element.

- **Current behavior:** dropped.
- **Why:** it is structural plumbing. The actual relationship is already
  captured by the real connector (in `t_connector`) and resolved by
  `ReferenceResolver`. A `ProxyConnector` in `t_object` is a rendering/UX
  artifact, not a second model element.
- **Future:** no plan to preserve. If diagram rendering needs the proxy
  geometry, it should come from `t_diagram_objects`, not from treating the
  proxy as a class.

## Verifying counts

After transformation:

```
EA t_object (Class)        =  UML UmlClass count (in packages + orphan root)
EA t_object (Enumeration)  =  UML Enum count
EA t_object (DataType)     =  UML DataType count
```

If counts don't match, check for orphaned classes (objects whose `package_id`
has no row in `t_package`) — these surface at the document root via
`EaToUmlFactory#transform_orphan_classes`, not inside any package.
