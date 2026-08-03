# TODO.complete/71: Autoload audit — remove internal require

## Status: done

The user's rule: "never use require_relative (or 'require' with code
within your library due to load paths) and instead use ruby autoload".

## Sites fixed

1. `lib/ea/svg/parity/source.rb:3-5` — removed three internal
   `require` calls (`require "ea"`, `require "ea/sources/xmi/adapter"`).
   These classes are already autoloaded via `lib/ea/svg/parity.rb`
   and `lib/ea/sources/xmi.rb`. External `require "xmi"` kept.

2. `lib/ea/svg/parity/suite.rb:4` — removed
   `require "ea/svg/parity/checker"`. Already autoloaded via
   `lib/ea/svg/parity.rb`.

## Audit result

- `grep -rn "require_relative" lib/` → 0 hits (was already clean).
- `grep -rn '^require "' lib/ | grep -v external_gems` → 0 internal
  requires remaining (was 2).

All namespace directories under `lib/ea/` have their parent `.rb`
file with `autoload` entries — verified for all 50 sub-directories.
