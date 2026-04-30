return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")

		telescope.setup({
			defaults = {
				path_display = { "truncate " },
				-- Configure ripgrep to search hidden files but exclude .git
				vimgrep_arguments = {
					"rg",
					"--color=never",
					"--no-heading",
					"--with-filename",
					"--line-number",
					"--column",
					"--smart-case",
					"--hidden",
					"--glob=!**/.git/*", -- Exclude .git directories
				},
				-- Global file ignore patterns
				file_ignore_patterns = {
					"%.git/",
					"%.git\\",
					"node_modules/",
					"%.DS_Store",
				},
				mappings = {
					i = {
						["<C-k>"] = actions.move_selection_previous,
						["<C-j>"] = actions.move_selection_next,
						["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
						["<C-u>"] = false,
						["<C-d>"] = false,
					},
				},
			},
			pickers = {
				find_files = {
					hidden = true,
					-- Use fd if available (faster and better handling of ignore patterns)
					find_command = { "fd", "--type", "f", "--hidden", "--exclude", ".git" },
					-- Fallback for systems without fd
					-- find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
				},
				live_grep = {
					additional_args = function(opts)
						return { "--hidden", "--glob=!**/.git/*" }
					end,
				},
				grep_string = {
					additional_args = function(opts)
						return { "--hidden", "--glob=!**/.git/*" }
					end,
				},
			},
		})

		local builtin = require("telescope.builtin")

		-- Basic keymaps
		vim.keymap.set("n", "<C-p>", builtin.find_files, {})
		vim.keymap.set("n", "<leader>s", builtin.live_grep, {})
		vim.keymap.set("n", "<leader>gc", builtin.git_commits, {})
		vim.keymap.set("n", "<leader>gb", builtin.git_branches, {})

		telescope.load_extension("fzf")

		-- Enhanced keymaps with descriptions
		local keymap = vim.keymap

		-- File finding keymaps
		keymap.set(
			"n",
			"<leader>ff",
			"<cmd>Telescope find_files<cr>",
			{ desc = "Find files (including hidden, excluding .git)" }
		)
		keymap.set("n", "<leader>fg", "<cmd>Telescope git_files<cr>", { desc = "Find git files only" })
		keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Fuzzy find recent files" })

		-- Buffer and search keymaps
		keymap.set("n", "<leader>t", "<cmd>Telescope buffers<cr>", { desc = "List buffers" })
		keymap.set(
			"n",
			"<leader>fs",
			"<cmd>Telescope live_grep<cr>",
			{ desc = "Find string in cwd (including hidden, excluding .git)" }
		)
		keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>", { desc = "Find string under cursor in cwd" })

		-- Additional useful keymaps for different search scopes
		keymap.set("n", "<leader>fh", function()
			builtin.find_files({
				hidden = true,
				no_ignore = true,
				find_command = { "fd", "--type", "f", "--hidden", "--no-ignore", "--exclude", ".git" },
			})
		end, { desc = "Find ALL files (including ignored, excluding .git)" })

		keymap.set("n", "<leader>fsg", function()
			builtin.live_grep({
				additional_args = { "--hidden", "--no-ignore", "--glob=!**/.git/*" },
			})
		end, { desc = "Live grep in ALL files (including ignored, excluding .git)" })

		-- Utility keymap to search EVERYTHING including .git (just in case you need it)
		keymap.set("n", "<leader>fall", function()
			builtin.find_files({
				hidden = true,
				no_ignore = true,
				find_command = { "fd", "--type", "f", "--hidden", "--no-ignore" },
			})
		end, { desc = "Find EVERYTHING (including .git)" })

		-- Dataview picker - multiple JSON files
		local dataview_picker = require("config.dataview_picker")
		keymap.set("n", "<leader>o", function()
			dataview_picker.open("-all.json", "All Items")
		end, { desc = "Open all.json in dataview picker" })
		keymap.set("n", "<leader>Q", function()
			dataview_picker.open("-main.json", "Main Items")
		end, { desc = "Open main.json in dataview picker" })
		keymap.set("n", "<leader>W", function()
			dataview_picker.open("-secondary.json", "Secondary Items")
		end, { desc = "Open secondary.json in dataview picker" })
	end,
}
