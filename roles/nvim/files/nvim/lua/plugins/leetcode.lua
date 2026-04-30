local leet_arg = "leetcode.nvim"
-- return {
-- 	"kawre/leetcode.nvim",
-- 	dir = vim.fn.expand("~/workspaces/local/Desktop/leetcode.nvim"),
-- 	dev = true,
-- 	dependencies = {
-- 		"MunifTanjim/nui.nvim",
-- 	},
-- 	lazy = leet_arg ~= vim.fn.argv(0, -1),
-- 	lang = "javascript",
-- 	opts = { arg = leet_arg },
-- 	cmd = "Leet",
-- }
return {
	"kawre/leetcode.nvim",
  -- dir = vim.fn.expand("~/workspaces/local/Desktop/leetcode.nvim"),
  -- dev = true,
	lazy = false,
	dependencies = {
		"MunifTanjim/nui.nvim",
	},
	opts = { arg = leet_arg, lang = "python3" },
	config = function(_, opts)
		require("leetcode").setup(opts)
	end,
	cmd = "Leet",
}
