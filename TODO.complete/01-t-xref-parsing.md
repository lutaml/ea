# TODO.complete/01: Full t_xref parser

## Status: done

EA's `t_xref` table stores semi-structured metadata in a custom mini-language.
We currently only consume the stereotype-application rows for classifier
stereo labels. The full format is the richest single metadata source in QEA.

## Format observed

### Stereotype application

```
@STEREO;Name=FeatureType;FQName=GML::FeatureType;@ENDSTEREO;
```

Fields: `Name` (short), `FQName` (`tech::Stereo`).

### Per-label / element styling block

```
@PROP=NAME@ENDPROP;CX=19:CY=18:OX=-42:OY=-2:HDN=0:BLD=0:ITA=0:UND=0:CLR=-1:ALN=1:DIR=0:ROT=0;
```

Fields (colon-separated key=value pairs after `@PROP=NAME@ENDPROP;`):

| key | meaning |
|---|---|
| CX, CY | cell size for label box |
| OX, OY | label offset from anchor |
| HDN | hidden (0/1) |
| BLD | bold (0/1) |
| ITA | italic (0/1) |
| UND | underline (0/1) |
| CLR | font color (signed int; -1 = default) |
| ALN | alignment (0=left, 1=center, 2=right) |
| DIR | text direction |
| ROT | rotation in degrees |

### CustomProperties

```
@CUSTOM;Name=...;Value=...;Type=...;@ENDCUSTOM;
```

(Repeated; semicolon-separated list.)

### diagram properties

Type=`diagram properties`. Carries display options as a `;`-separated list.

## Volume observed (plateau v5.1 QEA)

| Type | Count |
|---|---|
| element property | 599 |
| connectorSrcEnd property | 352 |
| diagram properties | 181 |
| attribute property | 68 |
| connector property | 34 |
| connectorDestEnd property | 12 |

Total: ~1246 rows in one real-world QEA.

## Plan

1. Add `Ea::Sources::Qea::XrefParser` — pure module, no state, parses one
   `Description` string into a structured `XrefRecord` (value object).
2. Define `XrefRecord` and `XrefStyleBlock` value objects in
   `lib/ea/sources/qea/xref/` (autoload from `xref.rb`).
3. Wire into `DiagramBuilder` and `ClassifierBuilder`:
   - element property → per-element label style
   - connectorSrcEnd / connectorDestEnd → per-end label style
   - diagram properties → PDATA overrides
4. Apply `BLD/ITA/UND/CLR/ALN/DIR/ROT` to connector labels in
   `lib/ea/svg/ea_emitter/label/`.

## OCP / MECE

- New namespace `Ea::Sources::Qea::Xref` with parser + value objects.
- `XrefParser.parse(description)` returns typed records — no mutation.
- Renderers consume records via `XrefStyleBlock` interface; no string
  parsing in renderers.

## Acceptance

- Spec: parse a real `@STEREO;Name=FeatureType;FQName=GML::FeatureType;@ENDSTEREO;`
  → `{ stereotype: "FeatureType", fqname: "GML::FeatureType" }`.
- Spec: parse a `@PROP=...` block → all 12 fields populated correctly.
- Spec: `Ea.parse(plateau_v5_1_qea).xref_records.size` matches `SELECT COUNT(*) FROM t_xref`.
- Spec: applied BLD=1 on a connector label propagates to SVG output.
