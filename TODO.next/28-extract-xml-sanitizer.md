# 28 - Extract XmlSanitizer (single-pass empty-element strip)

## Status: DONE (2026-07-01)

## Problem
`Transformer#strip_empty_elements` (transformer.rb:70-81) works around
the xmi gem's round-trip-oriented `VALUE_MAP`, which forces empty
elements (`<generalization/>`, `<ownedEnd/>`) on every collection
mapping. For generation those are noise — the post-processor strips
them.

Two issues with the current implementation:

1. **O(N²) worst case.** It re-parses XPath until no removals happen:
   ```ruby
   while removed.positive?
     doc.xpath("//*[not(node()) and not(@*)]").each { |n| n.remove }
   end
   ```
   Removing a deeply nested empty element may expose its parent as
   newly empty, requiring another full-doc XPath scan.
2. **Mixed concern.** XML sanitation is not the Transformer's job;
   it's an output-shaping concern.

## Fix

1. Extract to `lib/ea/transformers/qea_to_xmi/xml_sanitizer.rb` as a
   standalone class with a single `call(xml) -> String` method.
2. Walk depth-first and remove in post-order — single pass. Removing
   the deepest empty first means its parent's emptiness is checked
   against the already-pruned subtree.

```ruby
class XmlSanitizer
  def self.call(xml)
    new(xml).call
  end

  def initialize(xml)
    @doc = Nokogiri::XML(xml)
  end

  def call
    prune_empty(@doc.root) if @doc.root
    @doc.to_xml
  end

  private

  def prune_empty(node)
    node.element_children.each { |child| prune_empty(child) }
    return unless node.element_children.empty? &&
                  node.text.strip.empty? &&
                  node.attributes.empty?
    node.remove
  end
end
```

The Transformer's `serialize` becomes:
```ruby
def serialize
  XmlSanitizer.call(build_root.to_xml(use_prefix: true))
end
```

This stays a workaround until the xmi gem Phase 2 (see TODO 21)
lands a generation-friendly value_map. When that lands, this entire
file can be deleted in a one-line change.

## Verification
- New `spec/ea/transformers/qea_to_xmi/xml_sanitizer_spec.rb` covers:
  - empty-doc / no-op
  - flat empty element stripped
  - element with attribute preserved
  - element with text preserved
  - element with non-empty child preserved
  - nested empty chain (`<a><b/></a>` → `<a/>` → removed) in one pass
- `XmlSanitizer.call(empty_xml)` returns empty doc cleanly.
- Transformer file drops another ~15 lines.
