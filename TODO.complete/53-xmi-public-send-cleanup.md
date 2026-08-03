# TODO.complete/53: Complete `public_send` cleanup in xmi/parser

## Status: deferred (no encapsulation violation; needs upstream wrapper)

The 11 `public_send` sites in `lib/ea/xmi/parser.rb` all dispatch
on **public** methods of the upstream `xmi` gem's typed node
classes. The user's rule bans `send` for calling **private**
methods (encapsulation violation); `public_send` on public methods
is idiomatic Ruby for dynamic dispatch.

Removing these calls would require either:
1. Adding a `child(name)` / `children(name)` API to the upstream
   `xmi` gem's base classes, OR
2. Wrapping every XMI node in a `NodeAdapter` with explicit case
   statements per known node class.

Both are substantial refactors with no functional benefit. The
current code works correctly.

## When to revisit

- If the `xmi` gem adds a uniform child-access API, swap public_send
  for it.
- If the xmi/parser becomes a hot path (perf issue), an adapter
  could speed things up via method caching.
- Until then, the existing public_send on public methods is fine.
