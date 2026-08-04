# TODO.complete/81: DRY — scope predicates + GUID conversion

## Status: done

## 1. Scope predicates (EaAttribute + EaOperation)

Identical `public?`, `private?`, `protected?` methods were duplicated
in both models. Extracted to `Ea::Qea::Models::ScopePredicate` mixin.

```ruby
# Before: 6 methods × 2 files = 12 method definitions
# After: 3 methods in 1 mixin, included in both
```

## 2. GUID conversion (ExtensionSerializer)

`strip_guid` in ExtensionSerializer was a local copy of the GUID→ID
conversion already available in `GuidFormat.ea_guid_to_xmi_id`.
Replaced 3 call sites with `GuidFormat.ea_guid_to_xmi_id(guid, prefix:
"EAPK")` and removed the dead `strip_guid` method.

```ruby
# Before
parent ? "EAPK_#{strip_guid(parent.ea_guid)}" : nil

# After
parent ? GuidFormat.ea_guid_to_xmi_id(parent.ea_guid, prefix: "EAPK") : nil
```

## Acceptance

- `bundle exec rspec` passes 2203 examples, 0 failures.
- Export output unchanged (405898 bytes).
