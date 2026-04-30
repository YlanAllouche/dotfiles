return {
	"hedyhli/outline.nvim",
	lazy = true,
	cmd = { "Outline", "OutlineOpen" },
	keys = { -- Example mapping to toggle outline
		{ "<leader>n", "<cmd>Outline<CR>", desc = "Toggle outline" },
	},
	opts = {
		outline_items = {
			show_symbol_lineno = true,
		},
		outline_window = {
			show_cursorline = true,
			hide_cursor = true,
		},
	},
}
