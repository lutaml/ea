# TODO.complete/04: t_operationparams parsing

## Status: open

`t_operationparams` stores the parameters of an operation (method).
We parse `t_operation` but lose the parameter list.

## Schema (basic.qea)

```
OperationID INTEGER, Name TEXT, Type TEXT, Default TEXT, Notes TEXT,
Pos INTEGER, Const INTEGER, Style TEXT, Kind TEXT (in/out/inout/return),
ea_guid TEXT, ...
```

## Volume

- basic.qea: 12 rows
- plateau v5.1: 0 (no operations)

## Plan

1. Add `Ea::Qea::Models::EaOperationParam` raw-row model.
2. Add `Ea::Model::Parameter` (already exists per `lib/ea/model/parameter.rb`).
3. Wire into `DatabaseLoader` and `OperationBuilder`.
4. Operation rendering: append `(name: Type, name2: Type2)` to operation line.

## OCP / MECE

- One builder per table (OperationBuilder owns t_operation + t_operationparams).
- Parameter rendering is owned by the operation compartment renderer.

## Acceptance

- Spec: parse basic.qea → operations on classes include parameter lists.
- Spec: parameter `kind` distinguishes `in/out/inout/return`.
- Spec: `Operation#parameters` returns ordered list (Pos-sorted).
