return {
	"nvim-neo-tree/neo-tree.nvim",
	-- branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	config = function()
		require("neo-tree").setup({
			enable_git_status = true,
			enable_diagnostics = true,
			open_files_do_not_replace_types = { "terminal", "trouble", "qf" },
			default_component_configs = {
				git_status = {
					symbols = {
						-- Change type
						added = "✚",
						modified = "✎",
						deleted = "✖",
						renamed = "󰁕",
						-- Status type
						untracked = "?",
						ignored = "󰒳",
						unstaged = "󰄱",
						staged = "✓",
						conflict = "",
					},
				},
			},
			filesystem = {
				follow_current_file = {
					enabled = true,
					leave_dirs_open = false,
				},
				filtered_items = {
					visible = false,
					hide_dotfiles = false,
					hide_gitignored = true,
				},
				use_libuv_file_watcher = true,
				hijack_netrw_behavior = "open_default",
				window = {
					mappings = {
						["<bs>"] = "navigate_up",
						["."] = "set_root",
						["H"] = "toggle_hidden",
						["/"] = "fuzzy_finder",
						["D"] = "fuzzy_finder_directory",
						["#"] = "fuzzy_sorter",
						["f"] = "filter_on_submit",
						["<c-x>"] = "clear_filter",
						["[g"] = "prev_git_modified",
						["]g"] = "next_git_modified",
					},
				},
			},
			git_status = {
				window = {
					position = "float",
					mappings = {
						-- Stage/unstage operations
						["<space>"] = "git_add_file",
						["u"] = "git_unstage_file",
						["U"] = "git_undo_last_commit",
						["A"] = "git_add_all",
						["R"] = "git_revert_file",
						-- Commit operations
						["c"] = "git_commit",
						["p"] = "git_push",
						["P"] = "git_commit_and_push",
						-- Navigation
						["j"] = "move_down",
						["k"] = "move_up",
						["o"] = "open",
						["<cr>"] = "open",
						-- Help
						["?"] = "show_help",
					},
				},
			},
		})

		-- vim.keymap.set("n", "<C-n>", ":Neotree filesystem toggle float<CR>", {}) -- now use ranger instead
		vim.keymap.set("n", "<A-n>", ":Neotree filesystem left toggle<CR>", {})
		vim.keymap.set("n", "<A-g>", ":Neotree git_status left toggle<CR>", {})
		vim.keymap.set("n", "<leader>bf", ":Neotree buffers reveal float<CR>", {})
		vim.keymap.set("n", "<leader>gs", ":Neotree git_status float<CR>", { desc = "Git status (floating)" })
	end,
}
