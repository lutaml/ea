# 04 - Repository API: Composition, Not Registry

## Status: ✅ DONE (revised — no registry)

## Design Decision

~~Use a loader registry where parser gems register at load time.~~

**REJECTED.** A load-time registry with `if defined?(Lutaml::UmlRepository)`
at the bottom of `ea.rb` is wrong:
- Hidden side effect at file load time
- Cross-gem coupling (exactly what we must not allow)
- Order-dependent — only works if `UmlRepository` is loaded first
- If a registry is needed, it belongs in `Lutaml::Uml`, not `UmlRepository`

## What was implemented instead: Composition

`Repository.from_file` only handles `.lur` (its own native format).
For all other formats, users **compose** the parsing:

```ruby
# Parse with the appropriate parser gem
document = Ea::Qea.parse("model.qea")  # → Lutaml::Uml::Document

# Wrap in a queryable repository
repo = Lutaml::UmlRepository::Repository.from_document(document)
```

This is clean because:
- **No cross-requires** — `lutaml-uml` knows nothing about `ea`
- **No load-time side effects** — `ea.rb` has no `if defined?` hacks
- **No hidden coupling** — the caller explicitly composes the pipeline
- **Each gem has one job** — `ea` parses, `lutaml-uml` provides metamodel + repository

## API Summary

| Method | Purpose |
|---|---|
| `Repository.from_document(doc)` | Wrap a pre-parsed `Lutaml::Uml::Document` |
| `Repository.from_file(path)` | Load `.lur` only; raises for others with guidance |
| `Repository.from_package(path)` | Load `.lur` package |
| `Repository.from_file_cached(source, &block)` | Cache to `.lur`; block parses source |

## What was removed

- `Repository.from_xmi` / `from_xmi_lazy` — no longer call `Lutaml::Xmi::Parsers::Xml`
- `Loader.from_xmi` — same
- The `register_loader` / `loader_for` registry — removed entirely
- `resolve_document` — removed
