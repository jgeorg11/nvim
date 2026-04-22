# CodeCompanion Workspace Rules

You are working on a personal Neovim configuration.

## Priorities

- Reliability over novelty.
- Minimal edits over broad cleanup.
- Local developer ergonomics over generic defaults.

## Expected Workflow

1. Inspect the relevant config before editing.
2. Change only the smallest section needed.
3. Verify with a headless Neovim startup when possible.
4. Call out any external dependency, login, API key, or binary requirement.

## Guardrails

- Do not hardcode secrets.
- Do not delete unrelated plugin settings.
- Do not assume GUI-specific environment loading.
- Prefer explicit adapter names and clear auth configuration.

## Good Outcomes

- A new plugin or adapter works with the user's current shell and machine setup.
- Errors are traced to the real source: config shape, auth, missing binary, model access, or quota.
