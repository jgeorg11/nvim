# Coding Workspace Agent Guide

This repository is user-managed code and configuration.

## Goals

- Keep the project reliable.
- Prefer small, reviewable edits.
- Preserve existing workflows, integrations, and conventions unless a change is explicitly requested.
- Favor changes that work in the user's local development environment.

## Working Rules

- Read the relevant files and surrounding context before editing.
- Do not remove existing configuration, dependencies, or integrations unless they are broken or clearly replaced.
- Keep adapter, model, endpoint, and tool configuration explicit.
- Prefer environment variables or local `.env` loading over hardcoding secrets.
- When adding new config or code, keep it compatible with the project's existing tooling and structure.

## Verification

- For configuration-only changes, run the lightest relevant validation command available.
- For code changes, run the smallest meaningful test, typecheck, lint, or smoke check that fits the edit.
- For integration changes, verify the selected adapter, auth method, endpoint, and any required external binaries.
- If a feature depends on an external CLI, service, login, API key, or local setup detail, state that dependency clearly.

## Editing Style

- Keep formatting consistent with the surrounding files.
- Add comments only when they clarify a non-obvious decision.
- Avoid broad refactors unless asked.
