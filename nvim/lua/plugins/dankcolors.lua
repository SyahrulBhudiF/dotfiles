return {
	{
		"RRethy/base16-nvim",
		priority = 1000,
		config = function()
			require('base16-colorscheme').setup({
				base00 = '#121318',
				base01 = '#121318',
				base02 = '#78797c',
				base03 = '#78797c',
				base04 = '#272728',
				base05 = '#d6d7db',
				base06 = '#d6d7db',
				base07 = '#d6d7db',
				base08 = '#af566e',
				base09 = '#af566e',
				base0A = '#546db1',
				base0B = '#47a054',
				base0C = '#8d9bbd',
				base0D = '#546db1',
				base0E = '#d5e1ff',
				base0F = '#d5e1ff',
			})

			vim.api.nvim_set_hl(0, 'Visual', {
				bg = '#78797c',
				fg = '#d6d7db',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Statusline', {
				bg = '#546db1',
				fg = '#121318',
			})
			vim.api.nvim_set_hl(0, 'LineNr', { fg = '#78797c' })
			vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = '#8d9bbd', bold = true })

			vim.api.nvim_set_hl(0, 'Statement', {
				fg = '#d5e1ff',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Keyword', { link = 'Statement' })
			vim.api.nvim_set_hl(0, 'Repeat', { link = 'Statement' })
			vim.api.nvim_set_hl(0, 'Conditional', { link = 'Statement' })

			vim.api.nvim_set_hl(0, 'Function', {
				fg = '#546db1',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Macro', {
				fg = '#546db1',
				italic = true
			})
			vim.api.nvim_set_hl(0, '@function.macro', { link = 'Macro' })

			vim.api.nvim_set_hl(0, 'Type', {
				fg = '#8d9bbd',
				bold = true,
				italic = true
			})
			vim.api.nvim_set_hl(0, 'Structure', { link = 'Type' })

			vim.api.nvim_set_hl(0, 'String', {
				fg = '#47a054',
				italic = true
			})

			vim.api.nvim_set_hl(0, 'Operator', { fg = '#272728' })
			vim.api.nvim_set_hl(0, 'Delimiter', { fg = '#272728' })
			vim.api.nvim_set_hl(0, '@punctuation.bracket', { link = 'Delimiter' })
			vim.api.nvim_set_hl(0, '@punctuation.delimiter', { link = 'Delimiter' })

			vim.api.nvim_set_hl(0, 'Comment', {
				fg = '#78797c',
				italic = true
			})

			local current_file_path = vim.fn.stdpath("config") .. "/lua/plugins/dankcolors.lua"
			if not _G._matugen_theme_watcher then
				local uv = vim.uv or vim.loop
				_G._matugen_theme_watcher = uv.new_fs_event()
				_G._matugen_theme_watcher:start(current_file_path, {}, vim.schedule_wrap(function()
					local new_spec = dofile(current_file_path)
					if new_spec and new_spec[1] and new_spec[1].config then
						new_spec[1].config()
						print("Theme reload")
					end
				end))
			end
		end
	}
}
