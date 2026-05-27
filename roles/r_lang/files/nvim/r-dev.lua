return {
	-- Optional R development drop-in owned by the R role.
	-- Copy or source this manually once the base R workflow feels stable enough.
	{
		"R-nvim/R.nvim",
		lazy = false,
		config = function()
			require("r").setup({
				auto_start = "no",
				objbr_auto_start = true,
				R_args = { "--quiet", "--no-save" },
				R_app = "radian",
				min_editor_width = 72,
				rconsole_width = 78,
				hook = {
					on_filetype = function()
						vim.keymap.set("n", "<Enter>", "<Plug>RDSendLine", { buffer = true })
						vim.keymap.set("v", "<Enter>", "<Plug>RSendSelection", { buffer = true })
					end,
				},
			})

			-- TODO: Decide whether lintr/styler should land through none-ls,
			-- direct commands, or a future dedicated R tooling layer.
			-- TODO: Revisit littler, archived colorout support, and data-viewer
			-- ergonomics once the basic interactive flow is stable.
		end,
	},
}
