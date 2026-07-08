# 05 — Remove ea conditional require workarounds

**Status: PENDING (depends on 01)**

## Problem
Multiple spec files use `begin/rescue LoadError` around
`require "lutaml/uml_repository"` because the published gem didn't
ship the file. After lutaml-uml 0.3.0 is released, these workarounds
are unnecessary noise.

## Files to simplify

### spec/spec_helper.rb
```ruby
# BEFORE:
begin
  require "lutaml/uml"
rescue LoadError
end
begin
  require "lutaml/uml_repository"
rescue LoadError
end

# AFTER:
require "lutaml/uml"
require "lutaml/uml_repository"
```

### spec/ea/diagram/extractor_spec.rb
```ruby
# BEFORE:
begin
  require "lutaml/uml_repository/repository"
rescue LoadError
end
RSpec.configure do ... skip ... end

# AFTER:
require "lutaml/uml_repository/repository"
```

### spec/ea/qea/verification/comprehensive_equivalence_spec.rb
Same pattern — remove begin/rescue + skip guard.

## Verification
- Full suite passes without any conditional requires.
- No `skip "lutaml/uml_repository not available"` messages.
