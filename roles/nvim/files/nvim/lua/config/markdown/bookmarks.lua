-- bookmarks.lua
local M = {}

-- Store state as buffer-specific tables
M.instances = {} -- Will hold buffer-specific data

-- Sanitize string for display (remove newlines and tabs)
function M.sanitize(str)
	if not str then
		return ""
	end
	return str:gsub("[\n\r\t]", " ")
end

-- Convert path to absolute path
function M.expand_path(path)
	if not path:match("^~/") then
		return vim.fn.expand("~/share/") .. path
	end
	return vim.fn.expand(path)
end

-- Create and display the bookmark buffer
function M.create_bookmark_buffer(json_file)
	local file = io.open(json_file, "r")
	if not file then
		vim.notify("Cannot open bookmark file: " .. json_file, vim.log.levels.ERROR)
		return
	end
	local content = file:read("*all")
	file:close()

	local success, decoded = pcall(vim.fn.json_decode, content)
	if not success or type(decoded) ~= "table" then
		vim.notify("Failed to decode JSON content.", vim.log.levels.ERROR)
		return
	end

	-- Generate a unique buffer name based on the file path
	local buffer_name = "bookmarks://" .. vim.fn.fnamemodify(json_file, ":t:r")

	-- Check if we already have a buffer for this file
	local existing_buf_id = nil
	for buf_id, instance in pairs(M.instances) do
		if instance.buffer_name == buffer_name and vim.api.nvim_buf_is_valid(buf_id) then
			existing_buf_id = buf_id
			break
		end
	end

	-- Create a new buffer or reuse existing one
	local buf_id
	if existing_buf_id then
		buf_id = existing_buf_id
		-- Clear existing content
		vim.api.nvim_buf_set_option(buf_id, "modifiable", true)
		vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, {})
	else
		buf_id = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(buf_id, buffer_name)
	end

	-- Store buffer-specific data
	M.instances[buf_id] = {
		bookmarks = decoded,
		json_file = json_file,
		buffer_name = buffer_name,
		last_buffer_id = nil,
	}

	-- Prepare display lines
	local display_lines = {}
	for _, bookmark in ipairs(decoded) do
		local status = M.sanitize(bookmark.status)
		local summary = M.sanitize(bookmark.summary)
		local display_line = string.format("[%s] %s", status, summary)
		table.insert(display_lines, display_line)
	end

	-- Set lines in buffer
	vim.api.nvim_buf_set_option(buf_id, "modifiable", true)
	vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, display_lines)
	vim.api.nvim_buf_set_option(buf_id, "modifiable", false)

	-- Configure buffer options
	vim.api.nvim_buf_set_option(buf_id, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf_id, "bufhidden", "hide")
	vim.api.nvim_buf_set_option(buf_id, "swapfile", false)
	vim.api.nvim_buf_set_option(buf_id, "wrap", false)
	vim.api.nvim_buf_set_option(buf_id, "number", true)
	vim.api.nvim_buf_set_option(buf_id, "filetype", "bookmarks")

	-- Set keymaps
	local opts = { noremap = true, silent = true, buffer = buf_id }
	vim.keymap.set("n", "<CR>", function()
		M.goto_bookmark(buf_id)
	end, opts)
	vim.keymap.set("n", "dd", function()
		M.delete_bookmark(buf_id)
	end, opts)
	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(0, true)
	end, opts)

	-- Display the buffer in the current window
	vim.api.nvim_set_current_buf(buf_id)
end

-- Navigate to the selected bookmark
function M.goto_bookmark(buf_id)
	local instance = M.instances[buf_id]
	if not instance then
		vim.notify("Invalid bookmark buffer.", vim.log.levels.ERROR)
		return
	end

	local current_line = vim.api.nvim_win_get_cursor(0)[1]
	local bookmark = instance.bookmarks[current_line]
	if not bookmark then
		vim.notify("Invalid bookmark reference.", vim.log.levels.WARN)
		return
	end

	local file = M.expand_path(bookmark.file)
	local line_num = tonumber(bookmark.line) or 0

	if vim.fn.filereadable(file) == 0 then
		vim.notify("File does not exist: " .. file, vim.log.levels.ERROR)
		return
	end

	-- Store the current buffer name for Harpoon compatibility
	local current_buf_name = vim.api.nvim_buf_get_name(0)
	instance.last_buffer_id = vim.api.nvim_get_current_buf()

	-- Open the file (without splitting the window)
	local edit_cmd = string.format("edit %s", vim.fn.fnameescape(file))
	vim.cmd(edit_cmd)

	-- Go to the specified line if valid
	if line_num > 0 then
		vim.cmd(tostring(line_num))
		vim.cmd("normal! zz")
	else
		vim.cmd("normal! zz")
	end

	-- Explicitly set the alternate file for better Harpoon compatibility
	vim.fn.setreg("#", current_buf_name)
end

function M.delete_bookmark(buf_id)
	local instance = M.instances[buf_id]
	if not instance then
		vim.notify("Invalid bookmark buffer.", vim.log.levels.ERROR)
		return
	end

	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local current_line = cursor_pos[1]

	-- Remove the bookmark
	table.remove(instance.bookmarks, current_line)

	-- Write back to the JSON file
	local file = io.open(instance.json_file, "w")
	local encoded = vim.fn.json_encode(instance.bookmarks)
	file:write(encoded)
	file:close()

	-- Update the buffer
	vim.api.nvim_buf_set_option(buf_id, "modifiable", true)
	vim.api.nvim_buf_set_lines(buf_id, current_line - 1, current_line, false, {})
	vim.api.nvim_buf_set_option(buf_id, "modifiable", false)

	vim.notify("Bookmark deleted.", vim.log.levels.INFO)
end

-- Setup command
vim.api.nvim_create_user_command("BookmarkList", function(args)
	M.create_bookmark_buffer(args.args)
end, { nargs = 1, desc = "Open Bookmark List from JSON file" })

return M
