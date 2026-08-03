# TODO.complete/46: XSD Generator consolidation

## Status: done

`Ea::Export::Xsd::CliBridge` is glue that loads fixtures then
delegates to `Generator`. The bridge exists only because the CLI
needs to know about default fixture paths. Better: have Generator
accept optional mapping/namespaces with sensible defaults, eliminate
the bridge.

## Plan

1. Move fixture-path defaults into Generator as keyword args.
2. Delete CliBridge.
3. Update Export CLI to call Generator directly.

## Acceptance

- No `CliBridge` class.
- `ea export xsd` produces same output.
