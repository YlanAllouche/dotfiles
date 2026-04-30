-- {
-- 	"OXY2DEV/foldtext.nvim",
-- 	lazy = false,
-- },

return {
	"chrisgrieser/nvim-origami",
	event = "VeryLazy",
	opts = {}, -- needed even when using default config

	-- recommended: disable vim's auto-folding
	init = function()
		vim.keymap.set("n", "[[", "zk", { noremap = true, silent = true })
		vim.keymap.set("n", "]]", "zj", { noremap = true, silent = true })
		-- vim.keymap.set("n", "<CR>", "za", { noremap = true, silent = true })
		-- vim.keymap.set("n", "<C-i>", "za", { noremap = true, silent = true })
		vim.opt.foldlevel = 99
		vim.opt.foldlevelstart = 99
	end,
}
