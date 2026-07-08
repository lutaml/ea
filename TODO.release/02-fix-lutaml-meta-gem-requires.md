# 02 — Fix lutaml meta-gem broken requires

**Status: PENDING**

## Problem
`lib/lutaml.rb` requires 6 files that don't exist:

```ruby
require "lutaml/converter"           # MISSING
require "lutaml/ea"                  # MISSING (ea uses Ea:: namespace)
require "lutaml/xmi"                 # MISSING (xmi uses Xmi:: namespace)
require "lutaml/qea"                 # MISSING
require "lutaml/model_transformations" # MISSING
require "lutaml/cli"                 # MISSING
```

`require "lutaml"` crashes immediately. The meta-gem is unusable.

## Fix
Remove the 6 broken requires. Keep only the ones that resolve to
real files in the gem's own `lib/` tree:

```ruby
require_relative "lutaml/version"
require "lutaml/lml"
require "lutaml/uml"
require "lutaml/uml_repository"
```

## Note
The meta-gem should NOT try to remap other gems' namespaces. The ea
gem uses `Ea::*`, the xmi gem uses `Xmi::*`. Users who want both should
`require "ea"` and `require "xmi"` explicitly.
