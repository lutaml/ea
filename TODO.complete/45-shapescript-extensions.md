# TODO.complete/45: ShapeScript extensions

## Status: done

Current interpreter handles only primitives. Real EA ShapeScript
files use variables, conditionals, and subshapes.

## Plan

1. Variables: `var x = 10;` then use `x` in expressions.
2. Arithmetic: `rectangle(0, 0, x * 2, y + 5);`
3. Conditionals: `if (hasproperty("stereotype")) { ... }`
4. Subshapes: `shape Inner { ... }` invoked by name.
5. Color references: `setfill("white");`, `setpen("#FF0000");`
6. Text: `label("Hello");`

## OCP

- Each extension = new AST node + evaluator case.

## Acceptance

- Spec: variable assignment + use in rectangle.
- Spec: conditional emits only matching branch.
- Spec: nested subshape invocation.
