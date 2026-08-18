local M = {}

local MAX_SESSIONS = 500
local CODEX_ROOT = vim.fn.expand(vim.env.CODEX_HOME or "~/.codex")

local function notify(message, level)
	vim.notify(message, level or vim.log.levels.INFO, { title = "CodeCompanion" })
end

local function read_json_line(line)
	if not line or line == "" then
		return nil
	end

	local ok, decoded = pcall(vim.json.decode, line)
	if ok then
		return decoded
	end
end

local function read_index()
	local index = {}
	local path = vim.fs.joinpath(CODEX_ROOT, "session_index.jsonl")
	local file = io.open(path, "r")
	if not file then
		return index
	end

	for line in file:lines() do
		local item = read_json_line(line)
		if item and item.id then
			index[item.id] = item
		end
	end

	file:close()
	return index
end

local function read_session_meta(path)
	local file = io.open(path, "r")
	if not file then
		return {}
	end

	local meta = {}
	for _ = 1, 20 do
		local line = file:read("*l")
		if not line then
			break
		end

		local item = read_json_line(line)
		if item and item.type == "session_meta" and type(item.payload) == "table" then
			meta = item.payload
			break
		end
	end

	file:close()
	return meta
end

local function id_from_path(path)
	return path:match("(%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x)%.jsonl$")
end

local function short_id(id)
	return id and id:sub(1, 8) or "unknown"
end

local function display_path(path)
	if not path or path == "" then
		return "No folder"
	end

	return vim.fn.fnamemodify(path, ":~")
end

local function folder_name(path)
	if not path or path == "" then
		return "No folder"
	end

	local name = vim.fn.fnamemodify(path, ":t")
	if name == "" then
		return path
	end

	return name
end

local function date_label(value)
	if type(value) == "string" and #value >= 16 then
		return value:sub(1, 10) .. " " .. value:sub(12, 16)
	end

	return "unknown date"
end

local function sort_value(path, updated_at)
	local stat = vim.uv.fs_stat(path)
	if stat and stat.mtime then
		return stat.mtime.sec
	end

	return updated_at or ""
end

local function list_codex_sessions()
	local sessions_dir = vim.fs.joinpath(CODEX_ROOT, "sessions")
	if vim.fn.isdirectory(sessions_dir) == 0 then
		return {}
	end

	local index = read_index()
	local sessions = {}
	local pattern = vim.fs.joinpath(sessions_dir, "**", "*.jsonl")

	for _, path in ipairs(vim.fn.glob(pattern, false, true)) do
		local meta = read_session_meta(path)
		local id = meta.id or id_from_path(path)
		if id then
			local indexed = index[id] or {}
			local updated_at = indexed.updated_at or meta.timestamp
			table.insert(sessions, {
				id = id,
				cwd = meta.cwd or "",
				path = path,
				sort = sort_value(path, updated_at),
				title = indexed.thread_name or meta.title or ("Codex session " .. short_id(id)),
				updated_at = updated_at,
			})
		end
	end

	table.sort(sessions, function(a, b)
		return tostring(a.sort) > tostring(b.sort)
	end)

	if #sessions > MAX_SESSIONS then
		local trimmed = {}
		for i = 1, MAX_SESSIONS do
			trimmed[i] = sessions[i]
		end
		sessions = trimmed
	end

	return sessions
end

local function group_sessions()
	local groups_by_cwd = {}

	for _, session in ipairs(list_codex_sessions()) do
		local cwd = session.cwd or ""
		local group = groups_by_cwd[cwd]
		if not group then
			group = {
				cwd = cwd,
				sessions = {},
				sort = session.sort,
				updated_at = session.updated_at,
			}
			groups_by_cwd[cwd] = group
		end

		table.insert(group.sessions, session)
		if tostring(session.sort) > tostring(group.sort) then
			group.sort = session.sort
			group.updated_at = session.updated_at
		end
	end

	local groups = vim.tbl_values(groups_by_cwd)
	table.sort(groups, function(a, b)
		return tostring(a.sort) > tostring(b.sort)
	end)

	return groups
end

local function extract_content(content)
	if type(content) == "string" then
		return content
	end

	if type(content) ~= "table" then
		return ""
	end

	local chunks = {}
	for _, part in ipairs(content) do
		if type(part) == "table" and type(part.text) == "string" then
			table.insert(chunks, part.text)
		end
	end

	return table.concat(chunks, "\n")
end

local function append_wrapped(lines, text)
	for line in vim.gsplit(text or "", "\n", { plain = true }) do
		table.insert(lines, line)
	end
end

function M.open_transcript(session)
	local file = io.open(session.path, "r")
	if not file then
		return notify("Could not read Codex session " .. short_id(session.id), vim.log.levels.ERROR)
	end

	local lines = {
		"# " .. session.title,
		"",
		"- Session: `" .. session.id .. "`",
		"- Folder: `" .. display_path(session.cwd) .. "`",
		"- Updated: " .. date_label(session.updated_at),
		"",
	}

	for line in file:lines() do
		local item = read_json_line(line)
		local payload = item and item.payload
		if item and item.type == "response_item" and payload and payload.type == "message" then
			local role = payload.role
			if role == "user" or role == "assistant" then
				local text = vim.trim(extract_content(payload.content))
				if text ~= "" then
					table.insert(lines, "## " .. (role == "user" and "User" or "Assistant"))
					table.insert(lines, "")
					append_wrapped(lines, text)
					table.insert(lines, "")
				end
			end
		end
	end

	file:close()

	vim.cmd("botright new")
	local bufnr = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.bo[bufnr].buftype = "nofile"
	vim.bo[bufnr].bufhidden = "wipe"
	vim.bo[bufnr].filetype = "markdown"
	vim.bo[bufnr].modifiable = false
	pcall(vim.api.nvim_buf_set_name, bufnr, "[Codex] " .. session.title .. " " .. short_id(session.id))
end

local function load_session_into_chat(chat, session)
	if not chat.acp_connection or not chat.acp_connection:is_ready() then
		return false
	end

	local updates = {}
	local ok = chat.acp_connection:load_session(session.id, {
		on_session_update = function(update)
			table.insert(updates, update)
		end,
	})

	if not ok then
		return false
	end

	require("codecompanion.interactions.chat.acp.commands").link_buffer_to_session(
		chat.bufnr,
		chat.acp_connection.session_id
	)
	require("codecompanion.interactions.chat.acp.render").restore_session(chat, updates)
	chat:set_title(session.title)
	notify("Resumed Codex session: " .. session.title)
	return true
end

function M.resume_codex_session(session, context)
	local chat = require("codecompanion").chat({
		auto_submit = false,
		context = context,
		title = session.title,
	})
	if not chat then
		return M.open_transcript(session)
	end

	local attempts = 0
	local function try_load()
		if chat.adapter.type ~= "acp" then
			return chat:change_adapter("codex", try_load)
		end

		if load_session_into_chat(chat, session) then
			return
		end

		attempts = attempts + 1
		if attempts < 40 then
			return vim.defer_fn(try_load, 100)
		end

		notify("Could not resume through ACP; opening read-only transcript.", vim.log.levels.WARN)
		M.open_transcript(session)
	end

	try_load()
end

local function current_chat_items()
	local ok, registry = pcall(require, "codecompanion.interactions.shared.registry")
	if not ok then
		return {}
	end

	local items = {}
	for _, entry in ipairs(registry.list()) do
		table.insert(items, {
			name = entry.description ~= "" and entry.description or entry.name,
			description = "Open Neovim chat buffer",
			callback = entry.open,
		})
	end

	return items
end

local function session_items(group, context)
	local items = {}
	for _, session in ipairs(group.sessions) do
		table.insert(items, {
			name = session.title,
			description = date_label(session.updated_at) .. "  " .. short_id(session.id),
			callback = function()
				M.resume_codex_session(session, context)
			end,
		})
	end

	return items
end

function M.open_chat_groups(context)
	local items = {}
	local open_chats = current_chat_items()

	if #open_chats > 0 then
		table.insert(items, {
			name = "Current Neovim session",
			description = #open_chats .. " open chats",
			picker = {
				prompt = "Open Neovim chat",
				columns = { "name", "description" },
				items = open_chats,
			},
		})
	end

	for _, group in ipairs(group_sessions()) do
		table.insert(items, {
			name = folder_name(group.cwd),
			description = display_path(group.cwd) .. "  " .. #group.sessions .. " chats  latest " .. date_label(
				group.updated_at
			),
			picker = {
				prompt = "Codex sessions in " .. display_path(group.cwd),
				columns = { "name", "description" },
				items = function()
					return session_items(group, context)
				end,
			},
		})
	end

	if #items == 0 then
		table.insert(items, {
			name = "No chats found",
			description = "No CodeCompanion buffers or Codex sessions found under " .. CODEX_ROOT,
			callback = function()
				notify("No CodeCompanion buffers or Codex sessions found.")
			end,
		})
	end

	return items
end

local function context_block(context)
	local lines = {
		"Working directory: " .. vim.fn.getcwd(),
		"Current file: " .. (context.path or "[No file]"),
	}

	if context.is_visual and context.lines and #context.lines > 0 then
		table.insert(lines, "")
		table.insert(lines, "Current selection:")
		table.insert(lines, "```" .. (context.filetype or ""))
		vim.list_extend(lines, context.lines)
		table.insert(lines, "```")
	end

	return table.concat(lines, "\n")
end

local function codex_prompt(name, description, content, opts)
	opts = opts or {}
	return {
		interaction = "chat",
		description = description,
		opts = vim.tbl_extend("force", {
			auto_submit = true,
			stop_context_insertion = true,
		}, opts),
		prompts = {
			{
				role = "user",
				content = function(context)
					return content(context) .. "\n\n" .. context_block(context)
				end,
			},
		},
		name = name,
	}
end

function M.prompt_library()
	return {
		["Chat"] = {
			interaction = "chat",
			description = "Create a new Codex chat",
			opts = {
				index = 1,
				stop_context_insertion = true,
			},
			prompts = {
				n = function()
					return require("codecompanion").chat()
				end,
				v = {
					{
						role = "system",
						content = function(context)
							return "Act as a senior "
								.. context.filetype
								.. " developer. Give direct, practical guidance."
						end,
					},
					{
						role = "user",
						content = function(context)
							return "I have the following code:\n\n```"
								.. context.filetype
								.. "\n"
								.. table.concat(context.lines or {}, "\n")
								.. "\n```\n\n"
						end,
						opts = {
							contains_code = true,
						},
					},
				},
			},
		},

		["Open Chats ..."] = {
			interaction = " ",
			description = "Open current chats or resume Codex sessions by folder",
			opts = {
				index = 2,
				stop_context_insertion = true,
			},
			picker = {
				prompt = "Open chat",
				columns = { "name", "description" },
				items = function(context)
					return M.open_chat_groups(context)
				end,
			},
		},

		["Code workflow"] = codex_prompt("Code workflow", "Plan, edit, and verify with Codex", function()
			return [[Start a Codex-style coding workflow for the task I provide next.

Workflow:
1. Restate a concise plan.
2. Inspect the relevant files before editing.
3. Make the smallest reviewable change.
4. Run the lightest meaningful verification.
5. End with changed files, verification, and any remaining risks.]]
		end, {
			index = 3,
			user_prompt = true,
		}),

		["Review changes"] = codex_prompt("Review changes", "Review the current git diff", function()
			return [[Review the current repository changes.

Start by running git status and inspecting staged plus unstaged diffs. Lead with concrete findings ordered by severity, with file and line references when possible. Do not edit files unless I ask.]]
		end, {
			index = 4,
		}),

		["Edit selection"] = codex_prompt(
			"Edit selection",
			"Use Codex to revise the current file or selection",
			function()
				return [[Edit the current file or selected code according to the instruction I provide next.

Use repository conventions, inspect surrounding context first, and verify the edit if a lightweight check is available.]]
			end,
			{
				index = 5,
				user_prompt = true,
			}
		),

		["Commit changes"] = codex_prompt("Commit changes", "Review, stage, verify, and commit changes", function()
			return [[Create a git commit for the current repository changes.

Workflow:
1. Run git status and inspect staged, unstaged, and untracked changes.
2. Decide whether the changes belong in one commit. Ask before including unrelated or surprising files.
3. Run the lightest relevant verification available.
4. Stage the appropriate files and create a concise conventional commit message.
5. Report the commit hash and what was included.

Do not push.]]
		end, {
			index = 6,
		}),

		["Commit and push"] = codex_prompt("Commit and push", "Commit changes, then push the branch", function()
			return [[Commit the current repository changes and push the current branch.

Workflow:
1. Run git status and inspect staged, unstaged, and untracked changes.
2. Ask before including unrelated or surprising files.
3. Run the lightest relevant verification available.
4. Commit with a concise conventional commit message.
5. Push the current branch to its upstream, setting upstream if needed.

Never force-push unless I explicitly ask for it.]]
		end, {
			index = 7,
		}),

		["Push current branch"] = codex_prompt(
			"Push current branch",
			"Verify status and push the current branch",
			function()
				return [[Push the current git branch.

First inspect branch, upstream, remotes, and working tree status. If there are uncommitted changes, stop and ask what to do. Push the current branch to its upstream, setting upstream if needed. Never force-push unless I explicitly ask for it.]]
			end,
			{
				index = 8,
			}
		),

		["Upgrade tools"] = codex_prompt("Upgrade tools", "Upgrade local project tools safely", function()
			return [[Upgrade or repair local project tools for the task I provide next.

Inspect this repository's existing toolchain first. Keep dependency upgrades, lockfile changes, and config changes scoped and explicit. Check required external commands, credentials, or services before assuming they exist. Verify the result with the smallest meaningful command.]]
		end, {
			index = 9,
			user_prompt = true,
		}),
	}
end

return M
