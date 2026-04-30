return {
	"nvim-lualine/lualine.nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"tpope/vim-fugitive",
		"SmiteshP/nvim-navic",
	},
	config = function()
		local navic = require("nvim-navic")
		-- Setup navic highlights for icon colors
		local function setup_navic_highlights()
			vim.api.nvim_set_hl(0, "NavicIconsFile", { link = "Directory", default = true })
			vim.api.nvim_set_hl(0, "NavicIconsModule", { link = "Include", default = true })
			vim.api.nvim_set_hl(0, "NavicIconsNamespace", { link = "Include", default = true })
			vim.api.nvim_set_hl(0, "NavicIconsPackage", { link = "Include", default = true })
			vim.api.nvim_set_hl(0, "NavicIconsClass", { link = "Type", default = true })
			vim.api.nvim_set_hl(0, "NavicIconsMethod", { link = "Function", default = true })
			vim.api.nvim_set_hl(0, "NavicIconsProperty", { link = "@property", default = true })
			vim.api.nvim_set_hl(0, "NavicIconsField", { link = "@field", default = true })
			vim.api.nvim_set_hl(0, "NavicIconsConstructor", { link = "@constructor", default = true })
			vim.api.nvim_set_hl(0, "NavicIconsEnum", { link = "@type", default = true })
			vim.api.nvim_set_hl(0, "NavicIconsInterface", { link = "Type", default = true })
			vim.api.nvim_set_hl(0, "NavicIconsFunction", { link = "Function", default = true })
			vim.api.nvim_set_hl(0, "NavicIconsVariable", { link = "@variable", default = true })
			vim.api.nvim_set_hl(0, "NavicIconsConstant", { link = "Constant", default = true })
			vim.api.nvim_set_hl(0, "NavicIconsString", { link = "String", default = true })
			vim.api.nvim_set_hl(0, "NavicIconsNumber", { link = "Number", default = true })
			vim.api.nvim_set_hl(0, "NavicIconsBoolean", { link = "Boolean", default = true })
			vim.api.nvim_set_hl(0, "NavicIconsArray", { link = "@type", default = true })
			vim.api.nvim_set_hl(0, "NavicIconsObject", { link = "@type", default = true })
			vim.api.nvim_set_hl(0, "NavicIconsKey", { link = "@property", default = true })
			vim.api.nvim_set_hl(0, "NavicIconsNull", { link = "Constant", default = true })
			vim.api.nvim_set_hl(0, "NavicIconsEnumMember", { link = "@field", default = true })
			vim.api.nvim_set_hl(0, "NavicIconsStruct", { link = "Type", default = true })
			vim.api.nvim_set_hl(0, "NavicIconsEvent", { link = "@type", default = true })
			vim.api.nvim_set_hl(0, "NavicIconsOperator", { link = "Operator", default = true })
			vim.api.nvim_set_hl(0, "NavicIconsTypeParameter", { link = "TypeDef", default = true })
			vim.api.nvim_set_hl(0, "NavicText", { link = "Normal", default = true })
			vim.api.nvim_set_hl(0, "NavicSeparator", { link = "Comment", default = true })
		end

		-- Set up navic highlights on load and when colorscheme changes
		setup_navic_highlights()
		vim.api.nvim_create_autocmd("ColorScheme", {
			callback = function()
				setup_navic_highlights()
			end,
		})

		-- Configure navic
		navic.setup({
			icons = {
				File = "󰈙 ",
				Module = "󰏗 ",
				Namespace = "󰌗 ",
				Package = " ",
				Class = "󰌗 ",
				Method = "󰆧 ",
				Property = "󰜢 ",
				Field = "󰜢 ",
				Constructor = "󰆧 ",
				Enum = "󰕘 ",
				Interface = "󰕘 ",
				Function = "󰊕 ",
				Variable = "󰆧 ",
				Constant = "󰏿 ",
				String = "󰀬 ",
				Number = "󰎠 ",
				Boolean = "◩ ",
				Array = "󰅪 ",
				Object = "󰅩 ",
				Key = "󰌋 ",
				Null = "󰟢 ",
				EnumMember = "󰠔 ",
				Struct = "󰌗 ",
				Event = "󰓎 ",
				Operator = "󰆕 ",
				TypeParameter = "󰊄 ",
			},
			separator = " › ",
			depth_limit = 0,
			depth_limit_indicator = "..",
			safe_output = true,
			highlight = true,
			lsp = {
				auto_attach = true,
			},
		})

		-- Get filetype icon
		local function get_filetype_icon()
			local icon, _ = require("nvim-web-devicons").get_icon_color_by_filetype(vim.bo.filetype, { default = true })
			return icon and (icon .. " ") or ""
		end

		-- Custom diagnostics component
		local function diagnostics_component()
			local diagnostics = vim.diagnostic.count()
			if
				not diagnostics
				or (diagnostics[1] == 0 and diagnostics[2] == 0 and diagnostics[3] == 0 and diagnostics[4] == 0)
			then
				return ""
			end
			local result = {}
			local icons = { "✖ ", "⚠ ", "󰋼 ", "󱐋 " }
			local hl_groups = { "DiagnosticError", "DiagnosticWarn", "DiagnosticInfo", "DiagnosticHint" }
			for severity, count in pairs(diagnostics) do
				if count > 0 then
					table.insert(result, string.format("%%#%s#%s%d%%*", hl_groups[severity], icons[severity], count))
				end
			end
			return table.concat(result, " ")
		end

		-- Set statusline options to hide the bottom bar
		vim.opt.laststatus = 0
		vim.opt.cmdheight = 0 -- Minimize command line height

		-- Apply the "StatusLine" highlight to match your background
		vim.api.nvim_create_autocmd("ColorScheme", {
			callback = function()
				vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE", fg = "NONE", sp = "NONE" })
				vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "NONE", fg = "NONE", sp = "NONE" })
			end,
		})
		-- Apply it immediately
		vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE", fg = "NONE", sp = "NONE" })
		vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "NONE", fg = "NONE", sp = "NONE" })

		require("lualine").setup({
			options = {
				icons_enabled = true,
				theme = "auto",
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
				globalstatus = true,
				refresh = {
					statusline = 100,
					tabline = 1000,
					winbar = 100,
				},
				disabled_filetypes = {
					statusline = { "*" }, -- Disable statusline for all filetypes
					winbar = { "dashboard", "alpha", "starter", "help", "NvimTree" },
				},
			},

			-- Empty sections for the bottom statusline (completely disable it)
			sections = {},
			inactive_sections = {},

			-- Configure the top winbar with your components
			winbar = {
				lualine_a = {
					{
						function()
							return get_filetype_icon() .. vim.fn.fnamemodify(vim.fn.expand("%"), ":~:.")
						end,
						symbols = {
							modified = " ●",
							readonly = " ",
							unnamed = "[No Name]",
						},
					},
				},
				lualine_b = {},
				lualine_c = {
					{
						"navic",
						color_correction = "static",
						cond = function()
							return navic.is_available()
						end,
					},
				},
				lualine_x = {
					{
						diagnostics_component,
					},
				},
				lualine_y = {},
				lualine_z = {},
			},

			-- Configure the inactive winbar
			inactive_winbar = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = {
					{
						function()
							return get_filetype_icon() .. vim.fn.fnamemodify(vim.fn.expand("%"), ":~:.")
						end,
					},
				},
				lualine_x = {},
				lualine_y = {},
				lualine_z = {},
			},
		})

		-- Set up autocmd to ensure the bottom bar stays hidden
		vim.api.nvim_create_autocmd("VimEnter", {
			callback = function()
				vim.opt.laststatus = 0
				vim.opt.cmdheight = 0
			end,
		})
	end,
}
