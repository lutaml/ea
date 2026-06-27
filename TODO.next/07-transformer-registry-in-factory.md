# 07 - OCP: Use TransformerRegistry in EaToUmlFactory

## Status: ✅ DONE

## What was verified
`EaToUmlFactory#get_transformer` uses `TransformerRegistry` for dispatch:

```ruby
def get_transformer(type)
  return @transformers[type] if @transformers.key?(type)

  transformer_class = TransformerRegistry.transformer_for(type)
  raise ArgumentError, "Unknown transformer type: #{type}" unless transformer_class

  @transformers[type] = transformer_class.new(database)
end
```

Adding a new transformer type = registering in `TransformerRegistry`, no
modification to `EaToUmlFactory`. OCP-compliant.
