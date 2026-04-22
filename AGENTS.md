# Neovim Config Agent Guide

This repository is a personal Neovim configuration.

## Goals

- Keep startup reliable.
- Prefer small, reviewable edits.
- Preserve existing keymaps, plugin choices, and workflow unless a change is explicitly requested.
- Favor changes that work in a local macOS terminal-based Neovim setup.

## Working Rules

- Read the relevant `init.lua` section before editing.
- Do not remove existing plugin configuration unless it is broken or replaced by a clearly better supported path.
- Keep adapter and model configuration explicit.
- Prefer environment variables or local `.env` loading over hardcoding secrets.
- When adding new config, keep it compatible with `lazy.nvim`.

## Verification

- For config-only changes, run `nvim --headless '+qall'`.
- For CodeCompanion changes, verify the selected adapter name, auth method, and any required external binaries.
- If a feature depends on an external CLI, state that dependency clearly.

## Editing Style

- Keep Lua formatting consistent with the surrounding file.
- Add comments only when they clarify a non-obvious decision.
- Avoid broad refactors in `init.lua` unless asked.
