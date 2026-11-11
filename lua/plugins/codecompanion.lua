local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
local local_adapter = is_windows and "lm_studio" or "local_ollama"
local default_adapter = is_windows and "lm_studio" or "codex"
local inline_adapter = vim.env.CODECOMPANION_INLINE_ADAPTER
	or (is_windows and "lm_studio_inline")
	or ((vim.env.CODECOMPANION_OPENAI_URL and vim.env.CODECOMPANION_OPENAI_API_KEY) and "remote_openai" or local_adapter)
local codex_acp = vim.fn.executable("/opt/homebrew/opt/codex-acp/bin/codex-acp") == 1
		and "/opt/homebrew/opt/codex-acp/bin/codex-acp"
	or "codex-acp"
local codecompanion_actions = require("config.codecompanion_actions")
local config_dir = vim.fn.stdpath("config")

local function make_lm_studio_adapter(stream)
	local base_url = (vim.env.LM_STUDIO_URL or "http://localhost:1234"):gsub("/+$", "")
	local api_key = vim.env.LM_STUDIO_API_KEY or "lm-studio"

	local function get_models()
		local ok, response = pcall(function()
			return require("plenary.curl").get(base_url .. "/v1/models", {
				sync = true,
				headers = { Authorization = "Bearer " .. api_key },
			})
		end)
		if not ok or not response or (response.status and response.status >= 400) then
			return {}
		end

		local decoded, payload = pcall(vim.json.decode, response.body)
		if not decoded or type(payload) ~= "table" or type(payload.data) ~= "table" then
			return {}
		end
		return payload.data
	end

	local adapter_config = {
		url = base_url .. "/v1/responses",
		env = { api_key = api_key },
		parameters = {
			text = { format = { type = "text" } },
		},
		schema = {
			verbosity = {
				enabled = function()
					return false
				end,
			},
			model = {
				default = function()
					if vim.env.LM_STUDIO_MODEL and vim.env.LM_STUDIO_MODEL ~= "" then
						return vim.env.LM_STUDIO_MODEL
					end
					local models = get_models()
					return models[1] and models[1].id
				end,
				choices = function()
					local choices = {}
					for _, model in ipairs(get_models()) do
						if type(model.id) == "string" then
							choices[model.id] = { formatted_name = model.id }
						end
					end
					return choices
				end,
			},
		},
	}

	if stream == false then
		adapter_config.opts = { stream = false }
	end

	return require("codecompanion.adapters").extend("openai_responses", adapter_config)
end

return {
	{
		"olimorris/codecompanion.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		opts = {
			adapters = {
				http = {
					remote_openai = function()
						return require("codecompanion.adapters").extend("openai_compatible", {
							env = {
								url = vim.env.CODECOMPANION_OPENAI_URL,
								api_key = vim.env.CODECOMPANION_OPENAI_API_KEY,
								chat_url = "/v1/chat/completions",
								models_endpoint = "/v1/models",
							},
							schema = {
								model = {
									default = vim.env.CODECOMPANION_OPENAI_MODEL or "openai/gpt-oss-120b",
								},
							},
						})
					end,

					local_openwebui = function()
						return require("codecompanion.adapters").extend("openai_compatible", {
							env = {
								url = vim.env.CODECOMPANION_OPENWEBUI_URL,
								api_key = vim.env.CODECOMPANION_OPENWEBUI_API_KEY,
								chat_url = "/api/chat/completions",
								models_endpoint = "/api/models",
							},
							schema = {
								model = {
									default = vim.env.CODECOMPANION_OPENWEBUI_MODEL or "llama-4-maverick",
								},
							},
						})
					end,

					local_ollama = function()
						return require("codecompanion.adapters").extend("ollama", {
							schema = {
								model = {
									default = vim.env.OLLAMA_MODEL or "gpt-oss:20b",
								},
							},
						})
					end,

					lm_studio = function()
						return make_lm_studio_adapter(true)
					end,

					lm_studio_inline = function()
						return make_lm_studio_adapter(false)
					end,
				},

				acp = {
					codex = function()
						return require("codecompanion.adapters").extend("codex", {
							commands = {
								default = {
									codex_acp,
								},
							},
							defaults = {
								auth_method = "chat-gpt",
								session_config_options = {
									model = "gpt-6.1-sol",
									thought_level = "xhigh",
									model_config = "on", -- Fast mode
								},
							},
						})
					end,
				},
			},

			interactions = {
				chat = {
					adapter = default_adapter,

					tools = {
						opts = {
							collapse_tools = true,
							auto_submit_errors = true,
						},

						groups = {
							plan_execute = {
								description = "Plan first, then inspect, edit, and verify",
								tools = {
									"ask_questions",
									"file_search",
									"grep_search",
									"read_file",
									"get_changed_files",
									"get_diagnostics",
									"insert_edit_into_file",
									"run_command",
								},
								system_prompt = function(group, ctx)
									return string.format(
										[[
You are a careful coding agent working inside Neovim.

Date: %s
Operating system: %s

Follow this workflow:
1. Start with a short plan.
2. Inspect relevant files before editing.
3. Prefer minimal, reviewable changes.
4. Run verification commands when appropriate.
5. If something is ambiguous or risky, ask targeted questions.
6. End with a concise summary of what changed and what remains.
]],
										ctx.date,
										ctx.os
									)
								end,
								opts = {
									collapse_tools = true,
									ignore_system_prompt = true,
									ignore_tool_system_prompt = true,
								},
							},

							files_plus_memory = {
								description = "File tools plus persistent memory",
								tools = {
									"file_search",
									"grep_search",
									"read_file",
									"insert_edit_into_file",
									"get_changed_files",
									"memory",
								},
								opts = {
									collapse_tools = true,
								},
							},
						},

						opts_by_tool = {
							memory = {
								whitelist = {
									{ path = config_dir .. "/codecompanion/PERSONAL.md", as = "/personal" },
								},
							},
						},
					},

					slash_commands = {
						["plan"] = {
							callback = function(chat)
								chat:add_buf_message({
									role = "user",
									content = "@{plan_execute} Make a plan first, then inspect the codebase and propose the smallest safe change.",
								})
							end,
							description = "Use the planning agent workflow",
						},
					},
				},

				inline = {
					adapter = inline_adapter,
				},

				cmd = {
					adapter = is_windows and "lm_studio" or "copilot",
				},

				background = {
					adapter = is_windows and "lm_studio" or "copilot",
				},
			},

			display = {
				action_palette = {
					height = 12,
					opts = {
						show_preset_actions = false,
						show_preset_prompts = false,
						title = "Codex actions",
					},
				},
			},

			rules = {
				project = {
					description = "Project rules and coding guidance",
					parser = "CodeCompanion",
					files = {
						"AGENTS.md",
						"CLAUDE.md",
						".cursor/rules/*.mdc",
						".codecompanion/rules/*.md",
					},
				},
				personal = {
					description = "My persistent coding preferences",
					parser = "CodeCompanion",
					files = {
						config_dir .. "/codecompanion/PERSONAL.md",
					},
				},
			},

			prompt_library = vim.tbl_deep_extend("force", codecompanion_actions.prompt_library(), {
				markdown = {
					dirs = {
						vim.fn.getcwd() .. "/.prompts",
						config_dir .. "/codecompanion/prompts",
					},
				},
			}),
		},
	},
}
