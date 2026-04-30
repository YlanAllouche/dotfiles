return {
	"folke/noice.nvim",
	event = "VeryLazy",
	opts = {
		routes = {
			{
				view = "notify",
				filter = { event = "msg_showmode" },
			},
		},
		lsp = {
			progress = {
				enabled = true,
				format = "lsp_progress",
				format_done = "lsp_progress_done",
				throttle = 1000 / 30, -- frequency to update lsp progress message
				view = "mini",
			},
			override = {
				["vim.lsp.util.convert_input_to_markdown_lines"] = true,
				["vim.lsp.util.stylize_markdown"] = true,
				-- override cmp documentation with Noice (needs the other options to work)
				["cmp.entry.get_documentation"] = true,
			},
			hover = {
				enabled = true,
				silent = false, -- set to true to not show a message if hover is not available
				view = nil, -- when nil, use defaults from documentation
				opts = {}, -- merged with defaults from documentation
			},
			signature = {
				enabled = true,
				auto_open = {
					enabled = true,
					trigger = true, -- Automatically show signature help when typing a trigger character from the LSP
					luasnip = true, -- Will open signature help when jumping to Luasnip insert nodes
					throttle = 50, -- Debounce lsp signature help request by 50ms
				},
				view = nil, -- when nil, use defaults from documentation
				---@type NoiceViewOptions
				opts = {}, -- merged with defaults from documentation
			},
			message = {
				-- Messages shown by lsp servers
				enabled = true,
				view = "mini",
				opts = {},
			},
			-- defaults for hover and signature help
			documentation = {
				view = "hover",
				---@type NoiceViewOptions
				opts = {
					lang = "markdown",
					replace = true,
					render = "plain",
					format = { "{message}" },
					win_options = { concealcursor = "n", conceallevel = 3 },
				},
			},
		},
		notify = {
			enabled = true,
			view = "mini",
		},
		messages = {
			enabled = true, -- enables the Noice messages UI
			view = "mini", -- default view for messages
			view_error = "mini", -- view for errors
			view_warn = "mini", -- view for warnings
			view_history = "messages", -- view for :messages
			view_search = "virtualtext", -- view for search count messages. Set to `false` to disable
		},
		popupmenu = {
			enabled = true, -- enables the Noice popupmenu UI
			backend = "nui", -- backend to use to show regular cmdline completions
			kind_icons = true, -- set to `false` to disable icons
		},
	},
	dependencies = {
		-- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
		"MunifTanjim/nui.nvim",
		"j-hui/fidget.nvim",
	},
}
