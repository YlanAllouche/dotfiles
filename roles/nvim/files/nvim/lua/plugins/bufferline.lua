return {
	{
		"akinsho/bufferline.nvim",
		version = "*",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"lewis6991/gitsigns.nvim",
		},
		config = function()
			-- Ensure bufferline starts hidden
			vim.opt.showtabline = 0

			-- State variable
			local bufferline_enabled = false

			-- Setup bufferline
			require("bufferline").setup({
				options = {
					mode = "buffers",
					always_show_bufferline = false,

					-- Simple, clean separator style
					separator_style = "thin",

					-- Diagnostics from LSP
					diagnostics = "nvim_lsp",
					diagnostics_indicator = function(count, level)
						local icon = level:match("error") and " " or " "
						return " " .. icon .. count
					end,

					hover = {
						enabled = true,
						delay = 200,
						reveal = { "close" },
					},

					-- Show buffer numbers
					numbers = "ordinal",

					-- Enforce regular tabs
					enforce_regular_tabs = false,

					-- Show close button
					show_buffer_close_icons = true,

					-- Show indicator when buffer is selected
					indicator = {
						style = "icon",
						icon = "▎",
					},

					-- Sort buffers by directory
					sort_by = "directory",
				},
			})

			-- Function to update bufferline visibility
			local function update_bufferline_visibility()
				-- Count the number of listed buffers
				local buffer_count = 0
				for _ in pairs(vim.fn.getbufinfo({ buflisted = 1 })) do
					buffer_count = buffer_count + 1
				end

				-- Only show bufferline if enabled AND multiple buffers exist
				if bufferline_enabled and buffer_count > 1 then
					vim.opt.showtabline = 2
				else
					vim.opt.showtabline = 0
				end
			end

			-- Toggle bufferline with Alt-b
			vim.keymap.set("n", "<M-b>", function()
				bufferline_enabled = not bufferline_enabled
				update_bufferline_visibility()
			end, { desc = "Toggle bufferline" })

			-- Watch for buffer events to update visibility
			local bufferline_group = vim.api.nvim_create_augroup("BufferlineAutocommands", { clear = true })
			vim.api.nvim_create_autocmd({ "BufEnter", "BufAdd", "BufDelete" }, {
				group = bufferline_group,
				callback = function()
					update_bufferline_visibility()
				end,
			})

			-- Navigation
			vim.keymap.set("n", "<C-Tab>", "<Cmd>BufferLineCycleNext<CR>")
			vim.keymap.set("n", "<C-S-Tab>", "<Cmd>BufferLineCyclePrev<CR>")
			vim.keymap.set("n", "<leader>bc", "<Cmd>BufferLinePickClose<CR>", { desc = "Close buffer" })
			vim.keymap.set("n", "<leader>bp", "<Cmd>BufferLinePick<CR>", { desc = "Pick buffer" })
		end,
	},
}
