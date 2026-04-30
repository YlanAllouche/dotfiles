return {
	"3rd/image.nvim",
	build = false,
	opts = {
		processor = "magick_cli",
	},
	config = function()
		require("image").setup({
			integrations = {
				markdown = {
				resolve_image_path = function(document_path, image_path, fallback)
					local working_dir = vim.fn.getcwd()
					local share_root = vim.fn.expand("~/share")
					-- Format image path for Obsidian notes
					if working_dir:find(share_root, 1, true) then
						return working_dir .. "/" .. image_path
					end
						-- Fallback to the default behavior
						return fallback(document_path, image_path)
					end,
				},
			},
		})
	end,
}
