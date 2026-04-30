local function toggle_field_status(field_name, keymap)
	local current_line_nr = vim.api.nvim_win_get_cursor(0)[1]
	local current_line = vim.api.nvim_buf_get_lines(0, current_line_nr - 1, current_line_nr, false)[1] or ""

	local pattern_true = "%s%[" .. field_name .. ":: true%]" -- Match with optional leading whitespace
	local pattern_false = "%s%[" .. field_name .. ":: false%]" -- Match with optional leading whitespace

	if string.find(current_line, pattern_true) then
		local new_line = string.gsub(current_line, pattern_true, " [" .. field_name .. ":: false]", 1) -- Replace only the first occurrence
		vim.api.nvim_buf_set_lines(0, current_line_nr - 1, current_line_nr, false, { new_line })
	elseif string.find(current_line, pattern_false) then
		local new_line = string.gsub(current_line, pattern_false, " [" .. field_name .. ":: true]", 1) -- Replace only the first occurrence
		vim.api.nvim_buf_set_lines(0, current_line_nr - 1, current_line_nr, false, { new_line })
	else
		local new_line = current_line .. " [" .. field_name .. ":: true]"
		vim.api.nvim_buf_set_lines(0, current_line_nr - 1, current_line_nr, false, { new_line })
	end
end

local function toggle_active_status()
	toggle_field_status("active", "<leader>csa")
end

local function toggle_focus_status()
	toggle_field_status("focus", "<leader>csf")
end

local function setup_markdown_toggle()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "markdown",
		callback = function()
			vim.keymap.set("n", "<leader>csa", toggle_active_status, { buffer = true, desc = "Toggle Active Status" })
			vim.keymap.set("n", "<leader>csf", toggle_focus_status, { buffer = true, desc = "Toggle Focus Status" })
		end,
	})
end

setup_markdown_toggle()

