# Project Guidance

## Repository Context

This is a user-managed coding workspace with project-specific conventions and local workflow integrations.

## Preferred Approach

- Make the smallest safe change first.
- Keep dependency upgrades, config rewrites, and behavior changes separate unless they must move together.
- Treat local workflow integrations, internal endpoints, and user-specific tooling as critical unless the user says otherwise.

## Integration Notes

- Prefer supported upstream integrations over custom shims when the installed version supports them.
- Check for required external commands, services, or credentials before assuming an integration will work.
- Prefer auth through environment variables, local config, or explicit defaults, not inline secrets.

## When Unsure

- Inspect current docs, local source, or existing patterns before changing integration structure.
- Preserve existing custom rules, prompts, templates, memory paths, and workflow-specific settings unless asked to change them.
