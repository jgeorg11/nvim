local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
local default_adapter = is_windows and "local_ollama" or "codex"

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
								url = vim.env.ORNL_OPENAI_URL,
								api_key = vim.env.ORNL_OPENAI_API_KEY,
								chat_url = "/v1/chat/completions",
								models_endpoint = "/v1/models",
							},
							schema = {
								model = {
									default = "openai/gpt-oss-120b",
								},
							},
						})
					end,

					local_openwebui = function()
						return require("codecompanion.adapters").extend("openai_compatible", {
							env = {
								url = vim.env.FORERUNNER_OPENWEBUI_URL,
								api_key = vim.env.FORERUNNER_OPENWEBUI_API_KEY,
								chat_url = "/api/chat/completions",
								models_endpoint = "/api/models",
							},
							schema = {
								model = {
									default = vim.env.FORERUNNER_OPENWEBUI_MODEL or "llama-4-maverick",
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
				},

				acp = {
					codex = function()
						return require("codecompanion.adapters").extend("codex", {
							defaults = {
								auth_method = "chatgpt",
								session_config_options = {
									model = "gpt-5.4",
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
									{ path = "~/.config/nvim/codecompanion/PERSONAL.md", as = "/personal" },
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
			},

			strategies = {
				chat = {
					adapter = default_adapter,
				},
				inline = {
					adapter = default_adapter,
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
						"~/.config/nvim/codecompanion/PERSONAL.md",
					},
				},
			},

			prompt_library = {
				markdown = {
					dirs = {
						vim.fn.getcwd() .. "/.prompts",
						"~/.config/nvim/codecompanion/prompts",
					},
				},
			},
		},
	},
}
