# TODO-D 87: Reverse-engineer EA's InternalTechnologies encryption

## Status: open (encryption scheme unidentified)

EA's `InternalTechnologies/*.xml` files (66 files including
`GML_Tech.xml`) are stored in an encrypted/compressed format.
These contain stereotype icon definitions for built-in technologies
(GML, UML, SysML, BPMN, etc.) — including the FeatureType icon
needed for the polygon -4 parity gap.

## File format analysis

  - File: GML_Tech.xml, 3076 bytes
  - First bytes: 30 c6 3c f8 e4 d6 4b fd e0 dd 36 f5 57 84 8d 7b
  - NOT standard compression (zip/gzip/zlib headers absent)
  - NOT valid XML

## Hypotheses tested (all FAILED)

| Approach | Result |
|---|---|
| Single-byte XOR (256 keys) | No valid `<?xml` start |
| Multi-byte XOR assuming `<?xml version=` start | Key derives but doesn't repeat |
| zlib inflate at offsets 0-63 with wbits -15/-14/15/31/47 | No valid output |
| Byte rotation then zlib | No valid output |
| Byte subtraction (delta 1-255) then zlib | No valid output |
| XOR with position index | No valid output |
| Position-reversed XOR | No valid output |
| Add position modulo 256 | No valid output |

## Byte frequency analysis

Byte distribution at position mod 4 is fairly uniform (each byte
value appears 7-9 times per position). This is consistent with
**strong encryption** (AES, RC4, etc.) rather than simple XOR.

## EA.exe binary analysis

Located `MDGTechnology.cpp` debug tag at offset 0x4584684 in
EA.exe. Found references to `CryptEncrypt`/`CryptDecrypt` Windows
APIs and `aes_encrypt`/`aes_decrypt` SQL functions.

Searched EA.exe (70MB binary) for plaintext GML technology
content (`<MDG.Technology`, `ApplicationSchema`, `GML::FeatureType`,
`FeatureType`) — **zero matches**. The plaintext is NOT embedded
in the binary.

Extracted 19MB `.rsrc` section via `wrestool`. Contains many
`BSTRING` resources (UI strings, etc.) but none contain MDG
technology XML.

## Decryption options (none trivial)

1. **Run EA via Wine** to call the COM API:
   `Repository.GetTechnologyByClassID(...)` then export. Requires
   CrossOver/Wine GUI session — non-trivial setup.

2. **Ghidra/IDA disassembly** of MDGTechnology.cpp routine:
   locate the decryption function, identify the algorithm and
   hardcoded key. Requires reverse-engineering expertise and
   10+ hours of analysis.

3. **Debugger capture**: run EA under `winedbg`, set breakpoint
   at file-read for GML_Tech.xml, trace until plaintext appears
   in memory, dump it. Requires Wine debugging setup.

4. **Side-channel acquisition**: ask Sparx Systems support for
   the technology definition (they may provide it).

## Recommendation

The polygon -4 parity gap is small (4 missing stereotype
decorator icons across 188 diagrams). The effort to reverse-
engineer EA's encryption significantly exceeds the value of
closing this gap.

Recommend: DEFER this work until either:
- A user provides plaintext MDG exports from EA
- The `ea` gem adds Wine-based extraction as an optional feature
- A security researcher publishes the EA encryption scheme
