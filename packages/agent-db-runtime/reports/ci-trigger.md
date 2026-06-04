# CI Trigger

Purpose: trigger Agent DB Runtime Gates through a pull request path.

Expected workflow:

```txt
.github/workflows/agent-db-runtime-gates.yml
```

Expected value-loop gate:

```txt
npm run db:validate-value-loop
```

This file can be removed after CI execution evidence is captured.
