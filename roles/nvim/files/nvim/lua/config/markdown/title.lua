-- Store the floating window ID to manage it properly
local title_win_id = nil
local title_buf_id = nil

-- Function to close existing title window if it exists
local function close_title_window()
	if title_win_id and vim.api.nvim_win_is_valid(title_win_id) then
		vim.api.nvim_win_close(title_win_id, true)
		title_win_id = nil
	end

	if title_buf_id and vim.api.nvim_buf_is_valid(title_buf_id) then
		vim.api.nvim_buf_delete(title_buf_id, { force = true })
		title_buf_id = nil
	end
end

-- Extract title from markdown frontmatter
local function extract_title_from_frontmatter()
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	-- Check if the file has frontmatter (starts with ---)
	if #lines > 0 and lines[1] == "---" then
		local title = nil
		local frontmatter_end = false

		-- Look for title in frontmatter
		for i = 2, #lines do
			if lines[i] == "---" then
				frontmatter_end = true
				break
			end

			local title_match = lines[i]:match("^title:%s*(.+)$")
			if title_match then
				title = title_match:gsub('"', ""):gsub("'", "") -- Remove quotes if present
			end
		end

		if title and frontmatter_end then
			return title
		end
	end

	return nil
end

-- Display title in floating window
local function display_title_in_corner()
	-- Close any existing title window first
	close_title_window()

	-- Only proceed if we're in a markdown file
	local ft = vim.bo.filetype
	if ft ~= "markdown" then
		return
	end

	local title = extract_title_from_frontmatter()
	if not title then
		return
	end

	-- Create a buffer for the title
	title_buf_id = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(title_buf_id, 0, -1, true, { " " .. title .. " " })

	-- Set buffer options
	vim.api.nvim_buf_set_option(title_buf_id, "modifiable", false)
	vim.api.nvim_buf_set_option(title_buf_id, "bufhidden", "wipe")

	-- Calculate position (top right)
	local win_width = vim.api.nvim_win_get_width(0)
	local title_width = #title + 2

	local opts = {
		relative = "editor",
		width = title_width,
		height = 1,
		col = win_width - title_width - 2,
		row = 0,
		style = "minimal",
		border = "none", -- No border for minimalist look
		focusable = false,
	}

	-- Create the floating window
	title_win_id = vim.api.nvim_open_win(title_buf_id, false, opts)

	-- Set window options for a discreet appearance
	vim.api.nvim_win_set_option(title_win_id, "winblend", 0) -- No transparency needed since we'll have no background
	vim.api.nvim_win_set_option(title_win_id, "winhighlight", "Normal:MarkdownTitleFloat")

	-- Create highlight group for the title window - discreet style
	vim.cmd([[
        highlight default MarkdownTitleFloat guibg=NONE guifg=#6e88a6 gui=italic
    ]])
end

-- Function to update window position when resizing
local function update_title_position()
	if title_win_id and vim.api.nvim_win_is_valid(title_win_id) then
		local win_width = vim.api.nvim_win_get_width(0)
		local config = vim.api.nvim_win_get_config(title_win_id)
		local title_width = config.width

		-- Update position
		config.col = win_width - title_width - 2
		vim.api.nvim_win_set_config(title_win_id, config)
	end
end

-- Set up autocommands
local augroup = vim.api.nvim_create_augroup("MarkdownTitleDisplay", { clear = true })

-- Display title when entering markdown buffer or after writing
vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
	pattern = "*.md",
	group = augroup,
	callback = display_title_in_corner,
})

-- Close title window when leaving markdown buffer
vim.api.nvim_create_autocmd("BufLeave", {
	pattern = "*.md",
	group = augroup,
	callback = close_title_window,
})

-- Update position when window is resized
vim.api.nvim_create_autocmd("VimResized", {
	group = augroup,
	callback = update_title_position,
})

-- Handle colorscheme changes
vim.api.nvim_create_autocmd("ColorScheme", {
	group = augroup,
	callback = function()
		vim.cmd([[
            highlight default MarkdownTitleFloat guibg=NONE guifg=#6e88a6 gui=italic
        ]])
	end,
})

-- Initial run for current buffer if it's markdown
if vim.bo.filetype == "markdown" then
	display_title_in_corner()
end

-- Return the module (optional, for requiring)
return {
	display_title = display_title_in_corner,
	close_title = close_title_window,
}
