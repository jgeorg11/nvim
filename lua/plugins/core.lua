return {
	"NMAC427/guess-indent.nvim",
	"github/copilot.vim",
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-mini/mini.nvim",
		},
		opts = {
			ignore = function(buf)
				return vim.bo[buf].buftype == "nofile"
			end,
			nested = false,
			heading = {
				sign = false,
			},
			bullet = {
				icons = { "●", "○", "◆", "◇" },
			},
			code = {
				highlight = "RenderMarkdownH16Bg",
			},
			checkbox = {
				checked = {
					scope_highlight = "@markup.strikethrough",
				},
			},
		},
		ft = { "markdown", "codecompanion" },
	},
	{
		"lewis6991/gitsigns.nvim",
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
		},
	},
	{
		"folke/which-key.nvim",
		event = "VimEnter",
		opts = {
			delay = 0,
			icons = {
				mappings = vim.g.have_nerd_font,
				keys = vim.g.have_nerd_font and {} or {
					Up = "<Up> ",
					Down = "<Down> ",
					Left = "<Left> ",
					Right = "<Right> ",
					C = "<C-…> ",
					M = "<M-…> ",
					D = "<D-…> ",
					S = "<S-…> ",
					CR = "<CR> ",
					Esc = "<Esc> ",
					ScrollWheelDown = "<ScrollWheelDown> ",
					ScrollWheelUp = "<ScrollWheelUp> ",
					NL = "<NL> ",
					BS = "<BS> ",
					Space = "<Space> ",
					Tab = "<Tab> ",
					F1 = "<F1>",
					F2 = "<F2>",
					F3 = "<F3>",
					F4 = "<F4>",
					F5 = "<F5>",
					F6 = "<F6>",
					F7 = "<F7>",
					F8 = "<F8>",
					F9 = "<F9>",
					F10 = "<F10>",
					F11 = "<F11>",
					F12 = "<F12>",
				},
			},
			spec = {
				{ "<leader>s", group = "[S]earch" },
				{ "<leader>t", group = "[T]oggle" },
				{ "<leader>h", group = "Git [H]unk", mode = { "n", "v" } },
			},
		},
	},
	{
		"folke/tokyonight.nvim",
		priority = 1000,
		config = function()
			require("tokyonight").setup({
				style = "moon",
				styles = {
					comments = { italic = false },
				},
				on_highlights = function(hl, c)
					hl.RenderMarkdownH1Bg = { bg = c.blue1, fg = c.bg_dark }
					hl.RenderMarkdownH2Bg = { bg = c.cyan, fg = c.bg_dark }
					hl.RenderMarkdownH3Bg = { bg = c.green1, fg = c.bg_dark }
					hl.RenderMarkdownH4Bg = { bg = c.yellow, fg = c.bg_dark }
					hl.RenderMarkdownH5Bg = { bg = c.orange, fg = c.bg_dark }
					hl.RenderMarkdownH6Bg = { bg = c.magenta2, fg = c.bg_dark }
					hl.RenderMarkdownCode = { bg = c.bg_highlight }
					hl.RenderMarkdownBullet = { fg = c.blue }
					hl.RenderMarkdownQuote = { fg = c.cyan }
					hl.RenderMarkdownChecked = { fg = c.green1 }
					hl.RenderMarkdownUnchecked = { fg = c.yellow }
				end,
			})

			vim.cmd.colorscheme("tokyonight-moon")
		end,
	},
	{
		"folke/todo-comments.nvim",
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
	},
	{
		"echasnovski/mini.nvim",
		config = function()
			require("mini.ai").setup({ n_lines = 500 })
			require("mini.surround").setup()

			local statusline = require("mini.statusline")
			statusline.setup({ use_icons = vim.g.have_nerd_font })
			statusline.section_location = function()
				return "%2l:%-2v"
			end
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "master",
		build = ":TSUpdate",
		opts = {
			ensure_installed = {
				"bash",
				"c",
				"diff",
				"html",
				"lua",
				"luadoc",
				"markdown",
				"markdown_inline",
				"query",
				"vim",
				"vimdoc",
			},
			auto_install = true,
			highlight = {
				enable = true,
				additional_vim_regex_highlighting = { "ruby" },
			},
			indent = { enable = true, disable = { "ruby" } },
		},
		config = function(_, opts)
			vim.treesitter.query.set("markdown", "injections", [[
((html_block) @injection.content
  (#set! injection.language "html")
  (#set! injection.combined)
  (#set! injection.include-children))

((minus_metadata) @injection.content
  (#set! injection.language "yaml")
  (#offset! @injection.content 1 0 -1 0)
  (#set! injection.include-children))

((plus_metadata) @injection.content
  (#set! injection.language "toml")
  (#offset! @injection.content 1 0 -1 0)
  (#set! injection.include-children))

([
  (inline)
  (pipe_table_cell)
] @injection.content
  (#set! injection.language "markdown_inline"))
			]])
			vim.treesitter.query.set("bash", "injections", "")
			require("nvim-treesitter.configs").setup(opts)
		end,
	},
}
