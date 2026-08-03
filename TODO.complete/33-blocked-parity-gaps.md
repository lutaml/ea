# TODO.complete/33: Blocked parity gaps (deferral log)

## Status: done

Parity work that is currently blocked beyond reasonable effort. Documented
so future contributors don't re-investigate the same dead ends.

## polygon -4 (stereotype decorator icons)

**Status**: blocked on encryption.

The 4 missing polygons across 188 plateau diagrams are stereotype
decorator icons — small symbolic icons EA renders inside element bodies
when a stereotype provides a custom ShapeScript icon.

Blockers:
- EA's InternalTechnologies/*.xml are encrypted (AES/RC4-class).
- Plaintext shape definitions are not embedded in EA.exe.
- The ShapeScript DSL interpreter (TODO.complete/13) is high-effort.

See: TODO.diagrams/73, TODO.diagrams/87.

## rect +4 (plateau)

**Status**: under investigation. 4 extra `<rect>` elements across 188
diagrams. Per-diagram breakdown is in TODO.diagrams/74. Likely a missing
filter on diagram-frame elements or a duplicate package-outline render.

## text -40 (plateau)

**Status**: partially closed. Reduced from -98 to -40 via off-canvas
parent ghost line implementation. Remaining gap is the foreign-package
rule being too aggressive for some diagrams (TODO.diagrams/86).

## Ghost element discriminator

**Status**: no discriminator available from data. The icon appears for
some elements with HideIcon=0 but not others. EA's discriminator may
be UI state (selection) not data — unverifiable from QEA alone.

See: TODO.diagrams/73 (discriminator puzzle section).
