# TODO.complete/20: `ea diff` CLI command

## Status: done

Structural diff between two QEA files (or QEA vs XMI). Useful for:

- Detecting model drift between revisions
- Comparing XMI export round-trip against source QEA
- Auditing changes between team check-ins

## Plan

1. New command `Ea::Cli::Command::Diff` in `lib/ea/cli/command/diff.rb`.
2. Loads both files via `Ea.parse`.
3. Produces a structural diff:
   - Added / removed / modified packages, classifiers, attributes, operations, connectors.
4. Output formats: text (default), JSON (`--format json`).
5. Exit code: 0 if identical, 1 if differences found.

## API

```ruby
Ea::Diff.new(model_a, model_b).call
# => Ea::Diff::Result with added/removed/modified collections
```

## CLI

```
ea diff old.qea new.qea                    # text diff
ea diff old.qea new.qea --format json      # JSON output
ea diff old.qea new.qea --filter classes   # only class changes
```

## OCP / MECE

- `Ea::Diff::Comparator` base class with subclasses per entity type.
- New entity type = new comparator subclass, registered in `ComparatorRegistry`.
- Diff result is a value object; rendering is separate.

## Acceptance

- Spec: identical models → exit 0, empty diff.
- Spec: model with one added class → diff includes the class in `added`.
- Spec: renamed attribute → diff shows `modified` with old/new names.
- Spec: JSON output parses back to a structured diff.
