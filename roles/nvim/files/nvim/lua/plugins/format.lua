return {
	{
		{
			"Wansmer/treesj",
			keys = { "<leader>m", "<A-m>", "<A-S-m>" },
			dependencies = { "nvim-treesitter/nvim-treesitter" },
			config = function()
				require("treesj").setup({})
			end,
		},
	},
	{
		"stevearc/conform.nvim",
		lazy = true,
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local conform = require("conform")
			local function format_current_buffer()
				conform.format({
					lsp_fallback = true,
					async = false,
					timeout_ms = 1000,
				})
			end

			conform.setup({
				formatters_by_ft = {
					javascript = { "prettier" },
					typescript = { "prettier" },
					javascriptreact = { "prettier" },
					typescriptreact = { "prettier" },
					-- svelte = { "prettier" },
					css = { "prettier" },
					html = { "prettier" },
					json = { "prettier" },
					yaml = { "prettier" },
					markdown = { nil },
					graphql = { "prettier" },
					lua = { "stylua" },
					python = {
						"ruff_format",
						-- TODO: Consider switching to { "ruff_fix", "ruff_format" }
						-- once we want config-driven autofixes/import cleanup on save.
						-- Temporary Black fallback for Black-only repos: replace the
						-- formatter above with "black" instead of chaining both.
					},
				},
				format_on_save = {
					lsp_fallback = true,
					async = false,
					timeout_ms = 1000,
				},
			})

			vim.keymap.set({ "n", "v" }, "<leader>mp", format_current_buffer, { desc = "Format file or range (in visual mode)" })
			vim.keymap.set("n", "<M-f>", format_current_buffer, { desc = "Format current buffer" })
		end,
	},
}
