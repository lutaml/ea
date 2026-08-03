# 16 - Operation Compartment Rendering

## Status: DONE (2026-07-25)

## Outcome

New `Element::OperationRenderer` emits operations as a third
compartment below attributes (when classifier has operations).
Layout:

```
┌────────────────────┐
│ «DataType»         │  header
│ ClassName          │
├────────────────────┤
│ + attr: Type       │  attributes
├────────────────────┤
│ + method1()        │  operations
│ + method2(): Type  │
├────────────────────┤
│ literal1           │  enum literals (if Enumeration)
└────────────────────┘
```

Each operation emits as TWO `<text>` elements (visibility + content)
matching EA's attribute encoding. Operation signature format:
`+ name(params): ReturnType`.

`CompartmentGeometry` extended with `op_divider_y`, `op_first_y`,
`op_bottom_y` and adjusted `enum_divider_y` to follow op compartment.

## Note

In the current plateau XMI dataset, no classifiers have operations
(0/599). The renderer is implemented for completeness — future
XMI imports with operation data will render correctly.

## Files changed

- `lib/ea/svg/ea_emitter/element/operation_renderer.rb` — NEW
- `lib/ea/svg/ea_emitter/element.rb` — autoload
- `lib/ea/svg/ea_emitter/elements.rb` — invoke renderer, extend geometry
