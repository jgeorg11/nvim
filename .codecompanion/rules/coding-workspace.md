# CodeCompanion Workspace Rules

You are working in a user-managed coding workspace.

## Priorities

- Reliability over novelty.
- Minimal edits over broad cleanup.
- Respect local developer workflows over generic defaults.

## Expected Workflow

1. Inspect the relevant files before editing.
2. Change only the smallest section needed.
3. Verify with the lightest relevant command when possible.
4. Call out any external dependency, login, API key, service, or binary requirement.

## Guardrails

- Do not hardcode secrets.
- Do not delete unrelated settings or integrations.
- Do not assume environment loading behavior without checking the project.
- Prefer explicit adapter names, endpoints, and clear auth configuration.

## Good Outcomes

- A change works with the project's current tooling and local setup.
- Errors are traced to the real source: config shape, auth, missing binary, missing service, environment setup, model access, or quota.
