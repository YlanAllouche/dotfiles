local M = {}

M.instances = {}

function M.sanitize(str)
	if not str then
		return ""
	end
	return str:gsub("[\n\r\t]", " ")
end

function M.expand_path(path)
	if not path:match("^~/") then
		return vim.fn.expand("~/share/") .. path
	end
	return vim.fn.expand(path)
end

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

	local buffer_name = "bookmarks://" .. vim.fn.fnamemodify(json_file, ":t:r")

	local existing_buf_id = nil
	for buf_id, instance in pairs(M.instances) do
		if instance.buffer_name == buffer_name and vim.api.nvim_buf_is_valid(buf_id) then
			existing_buf_id = buf_id
			break
		end
	end

	local buf_id
	if existing_buf_id then
		buf_id = existing_buf_id
		vim.api.nvim_buf_set_option(buf_id, "modifiable", true)
		vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, {})
	else
		buf_id = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(buf_id, buffer_name)
	end

	M.instances[buf_id] = {
		bookmarks = decoded,
		json_file = json_file,
		buffer_name = buffer_name,
		last_buffer_id = nil,
	}

	local display_lines = {}
	for _, bookmark in ipairs(decoded) do
		local status = M.sanitize(bookmark.status)
		local summary = M.sanitize(bookmark.summary)
		local display_line = string.format("[%s] %s", status, summary)
		table.insert(display_lines, display_line)
	end

	vim.api.nvim_buf_set_option(buf_id, "modifiable", true)
	vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, display_lines)
	vim.api.nvim_buf_set_option(buf_id, "modifiable", false)

	vim.api.nvim_buf_set_option(buf_id, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf_id, "bufhidden", "hide")
	vim.api.nvim_buf_set_option(buf_id, "swapfile", false)
	vim.api.nvim_buf_set_option(buf_id, "wrap", false)
	vim.api.nvim_buf_set_option(buf_id, "number", true)
	vim.api.nvim_buf_set_option(buf_id, "filetype", "bookmarks")

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

	vim.api.nvim_set_current_buf(buf_id)
end

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

	local current_buf_name = vim.api.nvim_buf_get_name(0)
	instance.last_buffer_id = vim.api.nvim_get_current_buf()

	local edit_cmd = string.format("edit %s", vim.fn.fnameescape(file))
	vim.cmd(edit_cmd)

	if line_num > 0 then
		vim.cmd(tostring(line_num))
		vim.cmd("normal! zz")
	else
		vim.cmd("normal! zz")
	end

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

	table.remove(instance.bookmarks, current_line)

	local file = io.open(instance.json_file, "w")
	local encoded = vim.fn.json_encode(instance.bookmarks)
	file:write(encoded)
	file:close()

	vim.api.nvim_buf_set_option(buf_id, "modifiable", true)
	vim.api.nvim_buf_set_lines(buf_id, current_line - 1, current_line, false, {})
	vim.api.nvim_buf_set_option(buf_id, "modifiable", false)

	vim.notify("Bookmark deleted.", vim.log.levels.INFO)
end

vim.api.nvim_create_user_command("BookmarkList", function(args)
	M.create_bookmark_buffer(args.args)
end, { nargs = 1, desc = "Open Bookmark List from JSON file" })

return M
