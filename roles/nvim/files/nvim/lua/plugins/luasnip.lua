return {
	{
		"L3MON4D3/LuaSnip",
		dependencies = {
			-- "rafamadriz/friendly-snippets",
		},
		config = function()
			local ls = require("luasnip")
			local home = vim.fn.expand("~")
			local cwd = vim.fn.getcwd()

			-- Extend filetypes so snippets work across related file types
			ls.filetype_extend("javascriptreact", { "javascript" })
			ls.filetype_extend("typescriptreact", { "typescript", "javascript" })
			ls.filetype_extend("typescript", { "javascript" })

			-- Load snippets from multiple sources
			-- Priority: Lua format > VSCode format

			-- 1. Global snippets from ~/.config/nvim/lua/snippets (both lua and vscode formats)
			-- Load Lua snippets directly by requiring the files
			require("luasnip.loaders.from_lua").load({
				paths = home .. "/.config/nvim/lua/snippets",
			})
			-- Load VSCode JSON snippets
			require("luasnip.loaders.from_vscode").lazy_load({
				paths = home .. "/.config/nvim/lua/snippets",
			})

			-- 2. Project snippets from $CWD/.vscode/snippets (both lua and vscode formats)
			require("luasnip.loaders.from_lua").load({
				paths = cwd .. "/.vscode/snippets",
			})
			require("luasnip.loaders.from_vscode").lazy_load({
				paths = cwd .. "/.vscode/snippets",
			})

			-- 3. Project snippets from $CWD/snippets (both lua and vscode formats)
			require("luasnip.loaders.from_lua").load({
				paths = cwd .. "/snippets",
			})
			require("luasnip.loaders.from_vscode").lazy_load({
				paths = cwd .. "/snippets",
			})

			-- Keymaps for snippet expansion and navigation
			vim.keymap.set({ "i", "s" }, "<C-s>", function()
				if ls.expand_or_jumpable() then
					ls.expand_or_jump()
				end
			end, { silent = true, desc = "Expand or jump forward in snippet" })

			vim.keymap.set({ "i", "s" }, "<C-l>", function()
				if ls.jumpable(1) then
					ls.jump(1)
				end
			end, { silent = true, desc = "Jump forward in snippet" })

			vim.keymap.set({ "i", "s" }, "<C-h>", function()
				if ls.jumpable(-1) then
					ls.jump(-1)
				end
			end, { silent = true, desc = "Jump backward in snippet" })

			-- Choice node navigation
			vim.keymap.set({ "i", "s" }, "<C-n>", function()
				if ls.choice_active() then
					ls.change_choice(1)
				end
			end, { silent = true, desc = "Next choice in snippet" })

			vim.keymap.set({ "i", "s" }, "<C-p>", function()
				if ls.choice_active() then
					ls.change_choice(-1)
				end
			end, { silent = true, desc = "Previous choice in snippet" })
		end,
	},
}
