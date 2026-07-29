return {
	"nvim-treesitter/nvim-treesitter",
	dependencies = {
		{
			"nvim-treesitter/nvim-treesitter-textobjects",
			branch = "main",
			config = function()
				require("nvim-treesitter-textobjects").setup({
					select = {
						lookahead = true,
						selection_modes = {
							["@parameter.outer"] = "v",
							["@function.outer"] = "V",
							["@class.outer"] = "<c-v>",
						},
					},
				})
			end,
		},
	},
	keys = {
		{ "<M-o>", desc = "Increment Selection" },
		{ "<M-i>", desc = "Decrement Selection", mode = "x" },
		{ "]f", desc = "Next Function" },
		{ "]F", desc = "Next Function End" },
		{ "[f", desc = "Previous Function" },
		{ "[F", desc = "Previous Function End" },
		{ "]c", desc = "Next Class" },
		{ "]C", desc = "Next Class End" },
		{ "[c", desc = "Previous Class" },
		{ "[C", desc = "Previous Class End" },
		{ "]a", desc = "Next Parameter" },
		{ "]A", desc = "Next Parameter End" },
		{ "[a", desc = "Previous Parameter" },
		{ "[A", desc = "Previous Parameter End" },
	},
	init = function()
		local select = require("nvim-treesitter-textobjects.select")
		for lhs, query in pairs({ af = "@function.outer", ["if"] = "@function.inner", ac = "@class.outer", ic = "@class.inner", ["as"] = "@local.scope" }) do
			vim.keymap.set({ "x", "o" }, lhs, function()
				select.select_textobject(query, "textobjects")
			end)
		end
		local move = require("nvim-treesitter-textobjects.move")
		for lhs, spec in pairs({
			["]f"] = { "goto_next_start", "@function.outer" }, ["]F"] = { "goto_next_end", "@function.outer" },
			["[f"] = { "goto_previous_start", "@function.outer" }, ["[F"] = { "goto_previous_end", "@function.outer" },
			["]c"] = { "goto_next_start", "@class.outer" }, ["]C"] = { "goto_next_end", "@class.outer" },
			["[c"] = { "goto_previous_start", "@class.outer" }, ["[C"] = { "goto_previous_end", "@class.outer" },
			["]a"] = { "goto_next_start", "@parameter.inner" }, ["]A"] = { "goto_next_end", "@parameter.inner" },
			["[a"] = { "goto_previous_start", "@parameter.inner" }, ["[A"] = { "goto_previous_end", "@parameter.inner" },
		}) do
			vim.keymap.set({ "n", "x", "o" }, lhs, function()
				move[spec[1]](spec[2], "textobjects")
			end)
		end
	end,
	branch = "main",
	build = ":TSUpdate",
	lazy = false,
	opts = {
		sync_install = true,
		highlight = { enable = true },
		indent = { enable = true },
		ensure_installed = {
			"bash",
			"blade",
			"c",
			"diff",
			"html",
			"javascript",
			"jsdoc",
			"json",
			"jsonc",
			"lua",
			"luadoc",
			"luap",
			"markdown",
			"markdown_inline",
			"printf",
			"php",
			"python",
			"query",
			"regex",
			"toml",
			"tsx",
      "typst",
			"typescript",
			"vim",
			"vimdoc",
			"xml",
			"yaml",
		},
	},
	config = function(_, opts)
		vim.filetype.add({ pattern = { [".*%.blade%.php"] = "blade" } })
		require("nvim-treesitter").setup(opts)
	end,
}
