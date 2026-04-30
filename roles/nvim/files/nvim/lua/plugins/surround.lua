-- -- TODO: https://github.com/kylechui/nvim-surround
-- -- TODO: going to class
-- -- TODO: walking up the  tree
-- return {
-- 	"echasnovski/mini.surround",
-- 	opts = {
-- 		custom_surroundings = nil,
-- 		highlight_duration = 500,
-- 		mappings = {
-- 			add = "sa", -- Add surrounding in Normal and Visual modes
-- 			delete = "sd", -- Delete surrounding
-- 			find = "sf", -- Find surrounding (to the right)
-- 			find_left = "sF", -- Find surrounding (to the left)
-- 			highlight = "sh", -- Highlight surrounding
-- 			replace = "sr", -- Replace surrounding
-- 			update_n_lines = "sn", -- Update `n_lines`
--
-- 			suffix_last = "l", -- Suffix to search with "prev" method
-- 			suffix_next = "n", -- Suffix to search with "next" method
-- 		},
-- 		n_lines = 20,
-- 		respect_selection_type = false,
-- 		search_method = "cover",
-- 		silent = false,
-- 	},
-- 	{sdfsdf},
-- }
return {
	"kylechui/nvim-surround",
	version = "^3.0.0", -- Use for stability; omit to use `main` branch for the latest features
	event = "VeryLazy",
	config = function()
		require("nvim-surround").setup({
			-- Configuration here, or leave empty to use defaults
		})
	end,
}
