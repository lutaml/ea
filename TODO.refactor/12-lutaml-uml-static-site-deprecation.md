# 12 - lutaml-uml StaticSite Fate

## Status: DEFERRED (post-validation)

## Problem

Once `Ea::Spa` is stable, `Lutaml::UmlRepository::StaticSite` is
redundant for EA sources. Decide: deprecate, or repurpose as the
"UML-purist" view for non-EA sources.

## Approach

Three options:
1. **Deprecate entirely** — once EA users move to `ea spa`,
   remove from `lutaml-uml`. Cleanest.
2. **Keep as UML-purist SPA** — for users who want the abstracted
   UML view (e.g. after cross-vendor harmonization via
   `lutaml-uml`). Document as a separate use case.
3. **Keep as thin wrapper** — `lutaml-uml`'s SPA calls into
   `Ea::Spa` for EA sources, falls back to its own pipeline for
   non-EA. Hybrid.

Decision deferred until `Ea::Spa` proves itself on the plateau
model (TODO 11). Document the decision as an ADR when made.

## Verification

Decision recorded; downstream callers notified if deprecation.
