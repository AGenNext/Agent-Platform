# Governance Validations

This directory is the central place for repo governance validation rules.

CI/CD scripts must read rule definitions from here instead of hardcoding governance policy in workflow files or shell scripts.

## Files

- `no-python-business-logic.rules.tsv` - patterns that fail Python business logic checks.

## Rule Format

`no-python-business-logic.rules.tsv` is tab-separated:

```text
scope<TAB>label<TAB>pattern
```

Scopes:

- `content` - run the pattern against Python file contents with `rg -n`.
- `path` - run the pattern against Python file paths.

## Final Rule

Edit governance rules here first. CI/CD wrappers should stay thin.
