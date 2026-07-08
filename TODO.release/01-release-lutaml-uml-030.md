# 01 — Release lutaml-uml 0.3.0

**Status: PENDING**

## Problem
The local lutaml-uml has 10 unpushed commits (559 files, +354k LOC)
containing the UmlRepository + StaticSite + Vue frontend infrastructure.
None of this is on rubygems. The published versions (0.2.12, 1.0.0)
don't include any of it.

This blocks ea CI — `lutaml/uml_repository` is not installable from
rubygems.

## Steps
1. Commit all local changes on `chore/consolidate-todos` branch.
2. Bump version: `0.2.0` → `0.3.0`.
3. Verify `bundle exec rspec` passes.
4. Push branch + open PR.
5. Merge-rebase.
6. Trigger GHA release.

## Version rationale
0.3.0 not 0.2.13 because the UmlRepository + StaticSite is a major
feature surface. 0.3.0 continues the 0.x API line (Lutaml::Uml::UmlClass
etc.) that ea targets. Published 1.0.0 has a different API (renamed
classes) and should be ignored / yanked.

## Verification
- `gem list -r --exact lutaml-uml` shows 0.3.0.
- `gem content lutaml-uml --version 0.3.0 | grep uml_repository` succeeds.
