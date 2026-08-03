# TODO.complete/30: HeaderLines OCP refactor (provider chain)

## Status: done

`Ea::Svg::EaEmitter::Element::HeaderLines` is a monolithic module with
conditional logic for stereotype fallback, qualified name wrap, abstract
italic, instance spec, off-canvas parent ghost. Adding a new behavior
modifies this module — violates OCP.

## Current shape

```ruby
module HeaderLines
  def self.for(classifier, ...)
    return instance_lines(classifier) if instance_spec?
    stereotype_label = stereotype_for(classifier, ...)
    lines = []
    lines << [off_canvas_parent_name, :italic] if off_canvas_parent_name
    if abstract?
      lines << [stereotype_label, :normal] if stereotype_label
      lines.concat(wrapped_name_lines(..., :bold_italic, ...))
      return lines
    end
    lines << [stereotype_label, :normal] if stereotype_label
    lines.concat(wrapped_name_lines(..., :bold, ...))
    lines
  end
end
```

## Proposed: provider chain

Each contribution to the header is a `HeaderLineProvider`:

- `ParentGhostProvider` → emits italic parent name when off-canvas
- `StereotypeLabelProvider` → emits `«stereo»` label
- `NameProvider` → emits the name (handles wrap, abstract italic)

A chain composes them. Adding a new contribution = adding a new provider
class. No modification of existing providers.

```ruby
class HeaderLinePipeline
  PROVIDERS = [
    ParentGhostProvider,
    StereotypeLabelProvider,
    NameProvider,
  ].freeze

  def self.call(classifier, context)
    PROVIDERS.flat_map { |p| p.call(classifier, context) }
  end
end
```

## Plan

1. Extract each existing behavior into its own provider class.
2. Replace `HeaderLines.for` with `HeaderLinePipeline.call`.
3. Keep `HeaderLines` as a thin alias during migration; delete after.

## OCP / MECE

- Each provider owns one concern (MECE).
- New behavior = new provider (OCP).
- Providers are stateless; pure functions of (classifier, context).

## Acceptance

- Spec: pipeline output matches old HeaderLines output for all known cases.
- Spec: adding a new provider appends its lines without touching existing.
- Spec: each provider has its own spec file.
