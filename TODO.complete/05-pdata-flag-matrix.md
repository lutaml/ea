# TODO.complete/05: Complete PDATA/StyleEx flag matrix

## Status: done

EA's `t_diagram.PDATA` carries ~30 rendering flags as `Key=value;` pairs.
We currently parse only ~4 (`HideAtts`, `HideOps`, `HideParents`, `HideProps`).

## Full flag matrix

| Flag | Meaning | Status |
|---|---|---|
| HideAtts | Hide attribute compartment | ✅ parsed |
| HideOps | Hide operation compartment | ✅ parsed |
| HideParents | Hide off-canvas parent ghosts | ✅ parsed |
| HideProps | Hide properties | ✅ parsed |
| HideStereo | Hide stereotype labels | parsed, partial |
| HideEStereo | Hide extended stereotypes | not parsed |
| ShowTags | Show tagged values on elements | not parsed |
| ShowSN | Show sequence numbers | not parsed |
| OpParams | Show operation parameter types | not parsed |
| UseAlias | Display Alias instead of Name | not parsed |
| SuppCN | Suppress connector names | not parsed |
| ShowIcons | Show stereotype icons | parsed, icons deferred |
| ScalePI | Scale page indicators | not parsed |
| ShowCons | Show constraints | not parsed |
| ShowParentWarn | Warn about hidden parents | not parsed |

## Plan

1. Create `Ea::Sources::Qea::PdataFlags` value object with all flags
   as boolean accessors (default: EA defaults).
2. `DiagramBuilder#build_one` parses PDATA once, threads the flags object
   through `Diagram`.
3. Renderers query `diagram.pdata_flags.show_tags?`, etc., via attribute
   readers — no string parsing in renderer.
4. Document EA defaults in the value object (ShowTags default = false,
   UseAlias default = false, etc.).

## OCP / MECE

- Parsing in one place (PDATA parser).
- Value object carries typed flags.
- Renderers consume via boolean methods.
- New flag = new accessor on the value object; no renderer changes for
  existing flags.

## Acceptance

- Spec: `PdataFlags.parse("HideAtts=1;ShowTags=1;").show_tags? == true`.
- Spec: `PdataFlags.parse("").use_alias? == false` (default).
- Spec: UseAlias=1 in source → element header shows `alias` not `name`.
- Spec: OpParams=0 → operation line shows `op()` not `op(name: Type)`.
