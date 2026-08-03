# TODO-D 54: display_name for nested classes (DONE)

## Before

`HeaderLines#display_name` used both `visually_nested` AND
`nested_class_qualifier?` to decide whether to render the
qualified name:

```ruby
return name if visually_nested &&
               classifier.is_a?(Ea::Model::Classifier) &&
               nested_class_qualifier?(classifier, name)
```

The `visually_nested` check is a position-based heuristic (child
bounds inside parent bounds). For basic.qea's "Composition with
Substitution" diagram, Class B.1, B.2, B.3 are placed at y=-330
(off-canvas) while Class B is at y=-172. The position check returns
false, but the reference renders "Class B::Class B.1" (qualified).

## After

The `visually_nested` check is dropped. The `nested_class_qualifier?`
check alone determines the display:

```ruby
return name if classifier.is_a?(Ea::Model::Classifier) &&
               nested_class_qualifier?(classifier, name)
```

The qualifier is a parent class name (not a package name) when it
differs from the classifier's package name. EA always shows the
parent-class qualifier regardless of visual position.

## Verification

- basic.qea "Composition with Substitution": text delta -1 → 0 ✓
- 1764 specs pass
- Plateau unchanged (text overlap 64.5%)
- simple.qea unchanged (100%)
