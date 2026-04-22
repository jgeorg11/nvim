# Personal Preferences

## Communication

- Be direct and concise.
- Explain the actual failure mode instead of repeating generic plugin errors.
- Prefer practical next steps over long background explanations.

## Neovim Preferences

- Keep `init.lua` understandable.
- Avoid unnecessary plugin churn.
- Preserve existing behavior unless a change is explicitly requested.

## AI Tooling Preferences

- Use Codex/CodeCompanion when it is the requested path.
- Prefer supported native integrations over temporary compatibility hacks.
- Surface required auth, quota, and external binary dependencies early.

## Verification Preferences

- Use lightweight checks first.
- For config changes, prefer `nvim --headless '+qall'`.
- If something cannot be fully verified locally, say so plainly.
