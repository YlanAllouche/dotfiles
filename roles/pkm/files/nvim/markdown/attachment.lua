-- clipboard_image.lua

-- Configuration
local attachments_path = vim.fn.expand("~/share/attachments")
local relative_path = "/attachments" -- This will be used in the markdown link

-- Helper function to check if directory exists and create it if not
local function ensure_directory_exists(path)
	if vim.fn.isdirectory(path) == 0 then
		vim.fn.mkdir(path, "p")
	end
end

-- Helper function to generate a timestamp-based filename
local function generate_filename()
	return os.date("%Y-%m-%d-%H-%M-%S") .. ".png"
end

-- Function to check if clipboard contains an image and save it
local function paste_image_from_clipboard()
	-- Ensure attachments directory exists
	ensure_directory_exists(attachments_path)

	-- Generate filename
	local filename = generate_filename()
	local filepath = attachments_path .. "/" .. filename

	-- Check if wl-paste is available (for Wayland)
	if vim.fn.executable("wl-paste") == 1 then
		-- Try to save clipboard content as image using wl-paste
		local cmd = "wl-paste --type image/png > " .. vim.fn.shellescape(filepath) .. " 2>/dev/null"
		local result = vim.fn.system(cmd)
		local exit_code = vim.v.shell_error

		-- Check if the file was created and has content
		if exit_code == 0 and vim.fn.getfsize(filepath) > 0 then
			-- Insert markdown image link at cursor position with relative path
			local current_line_nr = vim.api.nvim_win_get_cursor(0)[1]
			local current_line = vim.api.nvim_buf_get_lines(0, current_line_nr - 1, current_line_nr, false)[1] or ""
			local cursor_col = vim.api.nvim_win_get_cursor(0)[2]

			-- Create the relative path link
			local image_link = "![" .. filename .. "](" .. relative_path .. "/" .. filename .. ")"

			-- Insert the image link at cursor position
			local new_line = current_line:sub(1, cursor_col) .. image_link .. current_line:sub(cursor_col + 1)
			vim.api.nvim_buf_set_lines(0, current_line_nr - 1, current_line_nr, false, { new_line })

			-- Move cursor after the inserted text
			vim.api.nvim_win_set_cursor(0, { current_line_nr, cursor_col + #image_link })

			vim.notify("Image saved as " .. filename, vim.log.levels.INFO)
			return true
		else
			-- Clean up empty file if it was created
			if vim.fn.filereadable(filepath) == 1 then
				vim.fn.delete(filepath)
			end

			vim.notify("No image data found in clipboard", vim.log.levels.WARN)
			return false
		end
	else
		vim.notify("wl-paste is not available. Please install it for Wayland clipboard support.", vim.log.levels.ERROR)
		return false
	end
end

-- Setup keymap
vim.keymap.set("n", "<leader>pi", paste_image_from_clipboard, { desc = "Paste Image from Clipboard" })

-- Return the module (optional, for requiring in other files)
return {
	paste_image_from_clipboard = paste_image_from_clipboard,
}
