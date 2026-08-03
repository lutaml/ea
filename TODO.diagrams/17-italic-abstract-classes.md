# 17 - Italic Rendering for Abstract Classes

## Status: DONE (2026-07-23)

## Outcome

Updated `Elements#header_lines` to handle the abstract + stereotype
combination: when a class is abstract AND has a stereotype, emit
both lines (stereotype normal, name italic with `_` prefix).

```ruby
if classifier.is_abstract
  lines << ["«abstract»", :normal] if classifier.stereotype_refs&.any?
  lines << ["_#{classifier.name}", :italic]
elsif classifier.stereotype_refs&.any?
  lines << ["«#{stereotype}»", :normal]
  lines << [name, :bold]
else
  lines << [name, :bold]
end
```

Abstract classes now render matching EA's encoding:
`<text style="font-style:italic;...">_TransportationObject</text>`.

## Files changed

- `lib/ea/svg/ea_emitter/elements.rb` — `header_lines` abstract+stereotype branch
