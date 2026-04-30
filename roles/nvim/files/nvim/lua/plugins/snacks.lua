return {
	"folke/snacks.nvim",
	opts = {
		-- image = {},
		-- indent = {},
		lazygit = {
			configure = true,
			config = {
				os = { editPreset = "nvim-remote" },
				gui = {
					nerdFontsVersion = "3",
				},
			},
			theme_path = vim.fs.normalize(vim.fn.stdpath("cache") .. "/lazygit-theme.yml"),
			theme = {
				[241] = { fg = "Special" },
				activeBorderColor = { fg = "MatchParen", bold = true },
				cherryPickedCommitBgColor = { fg = "Identifier" },
				cherryPickedCommitFgColor = { fg = "Function" },
				defaultFgColor = { fg = "Normal" },
				inactiveBorderColor = { fg = "FloatBorder" },
				optionsTextColor = { fg = "Function" },
				searchingActiveBorderColor = { fg = "MatchParen", bold = true },
				selectedLineBgColor = { bg = "Visual" }, -- set to `default` to have no background colour
				unstagedChangesColor = { fg = "DiagnosticError" },
			},
			win = {
				style = "lazygit",
			},
		},
		-- words = {},
		quickfile = {},
		-- 		statuscolumn = {
		-- 			left = { "mark", "sign", "git", "fold" }, -- priority of signs on the left (high to low)
		-- 			right = {}, -- nothing on the right - all signs on left
		-- 			folds = {
		-- 				open = false, -- show open fold icons
		-- 				git_hl = false, -- use Git Signs hl for fold icons
		-- 			},
		-- 			git = {
		-- 				patterns = { "GitSign", "MiniDiffSign" },
		-- 			},
		-- 			refresh = 50, -- refresh at most every 50ms
		-- 		},
	},
}
-- return {
-- 	"folke/snacks.nvim",
-- 	opts = function()
-- 		-- Toggle the profiler
-- 		Snacks.toggle.profiler():map("<leader>pp")
-- 		-- Toggle the profiler highlights
-- 		Snacks.toggle.profiler_highlights():map("<leader>ph")
-- 	end,
-- 	keys = {
-- 		{
-- 			"<leader>ps",
-- 			function()
-- 				Snacks.profiler.scratch()
-- 			end,
-- 			desc = "Profiler Scratch Bufer",
-- 		},
-- 	},
-- }
