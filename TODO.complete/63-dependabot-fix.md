# TODO.complete/63: Address dependabot vulnerability

## Status: done

`git push` reported: "GitHub found 1 vulnerability on lutaml/ea's
default branch (1 moderate)". Need to triage.

## Plan

1. Inspect the alert via `gh api repos/lutaml/ea/dependabot/alerts`.
2. If transitive (gem dependency): bump via Gemfile + bundle update.
3. If direct: upgrade affected gem.
4. Verify alert resolves.

## Acceptance

- Dependabot alert state is "dismissed" or "fixed".
- `git push` no longer reports vulnerability.
