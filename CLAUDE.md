# Project Guidance

## Repository Context

This is a user-managed Neovim configuration rooted around a single `init.lua`.

## Preferred Approach

- Make the smallest safe change first.
- Keep plugin upgrades and config rewrites separate unless the newer plugin requires matching config changes.
- Treat local workflow integrations such as CodeCompanion, Codex, OpenWebUI, and ORNL endpoints as user-critical.

## CodeCompanion Notes

- Prefer supported upstream adapters over custom shims when the installed plugin version supports them.
- Check for required external commands such as `codex-acp` before assuming an ACP adapter will work.
- Prefer auth through environment variables or explicit adapter defaults, not inline secrets.

## When Unsure

- Inspect current plugin docs or local plugin source before changing adapter structure.
- Preserve existing custom rule, prompt, and memory paths.
