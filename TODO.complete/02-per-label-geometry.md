# TODO.complete/02: Per-label Geometry box parsing

## Status: open

EA's `t_diagramlinks.Geometry` field encodes per-label styling boxes:

```
SX=20;SY=-31;EX=44;EY=-31;EDGE=2;LLB=CX=24:CY=13:OX=-42:OY=-1:HDN=0:BLD=0:ITA=0:UND=0:CLR=-1:ALN=1:DIR=0:ROT=0;LLE=...
```

Each label slot (`LLB`, `LLT`, `RLB`, `RLT`, `LLE`, `MLE`, `MTL`, `SLE`, `STE`)
carries its own font/style override. We currently parse position (SX/SY/EX/EY)
and label boxes for geometry but **drop the styling fields**.

## Plan

1. Extend `Ea::Sources::Qea::DiagramStyleParser` (or a new sibling
   `GeometryParser`) to parse the inner `key=value:key=value:...` block of
   each label slot into a `LabelStyle` value object.
2. Thread `LabelStyle` onto `DiagramConnector` end-labels (left/right,
   source/dest, role/mult).
3. Renderers consume `LabelStyle` via accessors; no string parsing in
   `lib/ea/svg/`.

## Value object shape

```ruby
LabelStyle = Struct.new(:hidden, :bold, :italic, :underline,
                        :color, :alignment, :direction, :rotation,
                        :offset_x, :offset_y, :cell_w, :cell_h, keyword_init: true)
```

## OCP / MECE

- Parsing lives in one place (Geometry parser).
- Value object carries typed fields.
- Renderers consume via attribute readers.

## Acceptance

- Spec: parse `LLB=CX=24:CY=13:OX=-42:OY=-1:HDN=0:BLD=1:ITA=0:UND=0:CLR=-1:ALN=1:DIR=0:ROT=0;`
  → `LabelStyle` with `bold=true, alignment=1, offset_x=-42`.
- Spec: a connector whose LLB has `BLD=1` renders bold left-label text.
- Spec: `LabelStyle#hidden?` suppresses label rendering entirely.

## Dependencies

- Requires TODO.complete/01 if the styling block is shared with t_xref.
  (They share the same `CX=..:OY=..:HDN=..:` shape — extract a shared
  `CellStyleParser`.)
