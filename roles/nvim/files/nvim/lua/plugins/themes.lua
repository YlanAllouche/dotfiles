return {
	{ "folke/tokyonight.nvim" },
	{ "bluz71/vim-nightfly-colors" },
	{
		"ray-x/aurora",
		init = function()
			vim.g.aurora_italic = 1
			-- vim.g.aurora_transparent = 1
			-- vim.g.aurora_bold = 1
		end,
	},
}
