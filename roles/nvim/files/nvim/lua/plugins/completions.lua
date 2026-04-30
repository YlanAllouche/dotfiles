return {
	{
		"hrsh7th/cmp-nvim-lsp",
	},
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"onsails/lspkind-nvim",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-path",
		},
		config = function()
			local cmp = require("cmp")
			local lspkind = require("lspkind")

			-- Function to intelligently adjust Pmenu colors for better contrast
			local function setup_pmenu_colors()
				local pmenu = vim.api.nvim_get_hl(0, { name = "Pmenu" })

				if not pmenu.bg then
					return
				end

				-- Extract RGB components from the background color
				local bg = pmenu.bg
				local r = bit.band(bit.rshift(bg, 16), 0xFF)
				local g = bit.band(bit.rshift(bg, 8), 0xFF)
				local b = bit.band(bg, 0xFF)

				-- Calculate luminance to determine if background is light or dark
				local luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255

				-- Create contrasting background color
				-- Use significantly darker or lighter color for contrast
				local new_bg
				if luminance < 0.5 then
					-- Dark background - darken it even more for contrast
					new_bg = 0x1a1a1a
				else
					-- Light/medium background - also use dark for strong contrast
					new_bg = 0x1a1a1a
				end

				-- Also ensure text color has good contrast
				-- If we're using dark background, use light text
				local fg = pmenu.fg or 0xffffff
				if luminance < 0.5 then
					fg = 0xffffff -- White text on dark background
				end

				vim.api.nvim_set_hl(0, "Pmenu", {
					fg = fg,
					bg = new_bg,
					blend = pmenu.blend,
				})
			end

			-- Set up Pmenu colors on startup and when colorscheme changes
			setup_pmenu_colors()
			vim.api.nvim_create_autocmd("ColorScheme", {
				group = vim.api.nvim_create_augroup("CmpPmenuColors", { clear = true }),
				callback = setup_pmenu_colors,
			})

			cmp.setup({
				window = {
					completion = {
						border = "none",
						winhighlight = "Normal:Pmenu,CursorLine:PmenuSel,Search:None",
					},
				},
				formatting = {
					fields = { "kind", "abbr", "menu" },
					format = function(entry, vim_item)
						local kind = require("lspkind").cmp_format({
							mode = "symbol_text",
							maxwidth = 50,
						})(entry, vim_item)

						local strings = vim.split(kind.kind, "%s", { trimempty = true })
						kind.kind = " " .. (strings[1] or "") .. " "
						kind.menu = "    (" .. (strings[2] or "") .. ")"

						-- Source (provider) information
						local source_menu = ({
							buffer = "[Buffer]",
							nvim_lsp = "[LSP]",
							nvim_lua = "[Lua]",
							latex_symbols = "[LaTeX]",
							path = "[Path]",
							lazydev = "[LazyDev]",
						})[entry.source.name]

						kind.menu = source_menu

						return kind
					end,
				},
				matching = {
					disallow_fuzzy_matching = false,
					disallow_fullfuzzy_matching = false,
					disallow_partial_fuzzy_matching = true,
					disallow_partial_matching = true,
					disallow_prefix_unmatching = false,
					disallow_symbol_nonprefix_matching = false,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<C-k>"] = cmp.mapping.select_prev_item(), -- previous suggestion
					["<C-j>"] = cmp.mapping.select_next_item(), -- next suggestion
				}),
				-- REMOVED luasnip from sources - no auto-suggestions for snippets
				sources = cmp.config.sources({
					{ name = "lazydev", group_index = 0 },
					{ name = "nvim_lsp" },
					{ name = "path" },
				}, {
					{ name = "buffer" },
				}),
			})

			-- Command line completion for : mode (Vim commands)
			cmp.setup.cmdline(":", {
				sources = cmp.config.sources({
					{ name = "cmdline" },
				}, {
					{ name = "path" },
				}),
				mapping = cmp.mapping.preset.cmdline(),
			})

			-- Search completion for / and ? mode
			cmp.setup.cmdline({ "/", "?" }, {
				sources = cmp.config.sources({
					{ name = "buffer" },
				}),
				mapping = cmp.mapping.preset.cmdline(),
			})
		end,
	},
}
