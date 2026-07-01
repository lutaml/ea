# 28 - Extract XmlSanitizer (single-pass empty-element strip)

## Status: DONE → SUPERSEDED (2026-07-01)

The XmlSanitizer was extracted into its own class on this branch
and used as a post-processing pass on the Transformer output. It was
then deleted when the upstream fix (xmi gem VALUE_MAP) made it
unnecessary.

## History

### Step 1: extracted into its own class
Originally `Transformer#strip_empty_elements` was a 12-line
method on the transformer that worked around the xmi gem's
round-trip-oriented `VALUE_MAP`. The workaround used a while-loop
with Nokogiri XPath to remove truly-empty elements.

Extracted to `lib/ea/transformers/qea_to_xmi/xml_sanitizer.rb`
as a focused class with a single-pass depth-first post-order walk.
Spec at `spec/ea/transformers/qea_to_xmi/xml_sanitizer_spec.rb`
(95 LOC, 11 examples).

### Step 2: superseded by upstream VALUE_MAP fix
The xmi gem refactor (`refactor/owned-end-schema-gap`) changed
`Xmi::VALUE_MAP` to skip empty elements on serialization:

```ruby
VALUE_MAP = {
  from: { nil: :empty, empty: :empty, omitted: :empty },
  to:   { nil: :omitted, empty: :omitted, omitted: :omitted },
}
```

After this change, the ea transformer emits no `<child/>` empty
elements at all — the post-processing pass was unnecessary.

### Step 3: deleted
`lib/ea/transformers/qea_to_xmi/xml_sanitizer.rb` and its spec
were deleted. The transformer's `serialize` method now just calls
`build_root.to_xml(use_prefix: true)` with no sanitization.

## Verification
- Full ea suite: 2005 examples, 0 failures, 37 pending
- Output contains zero truly-empty elements (no `<generalization/>`,
  no `<ownedEnd/>` without attributes).
- The transformation pipeline is now: build model graph →
  `to_xml(use_prefix: true)` → return. One pass, no Nokogiri
  re-parse, no element-mutation pass.

## Closes
TODO 21 §1 — "xmi gem empty-element rendering (architectural debt)".