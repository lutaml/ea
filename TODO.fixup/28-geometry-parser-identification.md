# 28 - Geometry Parser Identification

## Status: DONE (2026-07-25)

## Finding

Identified the geometry string parser function in EA.exe:

- **`FUN_03720c40`** at VMA 0x03720c40
- Size: 6691 addresses (~6.7 KB of compiled code)
- References strings: `SX=`, `SY=`, `EX=`, `EY=`, `EDGE=` (via push xrefs)
- Likely parses the full geometry string: SX/SY/EX/EY/EDGE/Path/LLB/LLT/LMT/LMB/LRT/LRB/IRHS/ILHS/SCME/SCTR

## Why full reverse-engineering is impractical

The function is too complex to fully understand without source
code or symbol information:

1. **Stack frame**: ~0x600 bytes (1500+ bytes of local variables)
2. **Branch complexity**: Hundreds of conditional branches for
   each geometry field
3. **Interleaved calls**: Many string-formatting and conversion
   functions called inline
4. **No type info**: All params/locals are `undefined4` or `int`
   without names or types

Ghidra's decompiler gives up with "Type propagation algorithm
not settling" warning.

## What this means for parity

The geometry parser CONSUMES the geometry string but does NOT
compute connector routing. Routing math (using SX/SY/EX/EY to
position line endpoints) happens in a separate function that's
called AFTER parsing.

Without identifying the routing function, we cannot extract
EA's exact attachment formula. Our `ConnectorRouter` uses
edge-center + 9px top-offset which matches the visible result
for most cases but doesn't capture EA's internal offset
adjustments.

## Conclusion

Static binary analysis has reached its practical limit. The
remaining parity gaps (49% of diagrams with >1 rect diff) come
from data and runtime-computed values that aren't extractable
from EA.exe alone.

To go further would require:
1. EA's PDB symbol file (proprietary, not distributed)
2. Runtime tracing via Wine + x64dbg/x64dbg
3. Direct API access to EA via COM automation

## Files changed

None.
