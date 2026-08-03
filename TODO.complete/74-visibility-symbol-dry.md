# TODO.complete/74: Visibility symbol DRY extraction

## Status: done

The UML visibility → single-character symbol mapping ("+" / "-" / "#"
/ "~") was duplicated in three SVG emitter files with slight
variations (trailing space vs not).

## Before

```ruby
# operation_renderer.rb
case operation.visibility
when "private"   then "- "
when "protected" then "# "
when "package"   then "~ "
else "+ "
end

# attribute_line_builder.rb
case property.visibility
when "private"   then "-"
when "protected" then "#"
when "package"   then "~"
else "+"
end

# end_label.rb — identical to attribute_line_builder
```

## After

All three call `Ea::Svg::EaEmitter::VisibilitySymbol.for(visibility,
with_space:)`. Adding a new visibility level (e.g., "implementation")
= one hash entry in `SYMBOLS`, not three case/when edits.

## Spec

`spec/ea/svg/ea_emitter/visibility_symbol_spec.rb` (9 examples).
