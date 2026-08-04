# TODO.complete/85: frozen_string_literal + rubocop + normalize_type spec

## Status: done

Final code-quality pass.

## 1. frozen_string_literal: true

10 files were missing the `# frozen_string_literal: true` magic
comment (or had the wrong variant `# frozen_string: true` which
Ruby does not recognize):

- `lib/ea/validation.rb`
- `lib/ea/mdg.rb` (+ `document.rb`, `loader.rb`, `xml.rb`, `registry.rb`)
- `lib/ea/model/ghost_label.rb`
- `lib/ea/svg/ea_emitter/ghost_labels.rb`
- `lib/ea/svg/ea_emitter/background.rb`
- `lib/ea/cli/command/render.rb`

All now have the correct comment at line 1. The `registry.rb` had
a non-functional `# frozen_string: true` variant — replaced with
the correct one.

## 2. Rubocop auto-correct

30 auto-correctable offenses fixed across the new/modified files:
trailing commas, hash syntax normalization, etc.

## 3. normalize_type spec

`ProfileSerializer#normalize_type` had no direct spec. Added 2
examples verifying Boolean → "Boolean" and unknown → "String".

## Result

- 2213 examples, 0 failures, 55 pending.
- All lib files have `frozen_string_literal: true`.
- New code is rubocop-clean (style offenses auto-corrected).
