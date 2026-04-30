-- task_utils.lua

-- Helper function to get the current date in YYYY-MM-DD format
local function get_current_date()
	return os.date("%Y-%m-%d")
end

-- Helper function to get the current datetime in ISO 8601 format
local function get_current_datetime()
	return os.date("%Y-%m-%dT%H:%M:%S")
end

-- Helper function to add or update a field in the current line
local function update_field(field_name, value)
	local current_line_nr = vim.api.nvim_win_get_cursor(0)[1]
	local current_line = vim.api.nvim_buf_get_lines(0, current_line_nr - 1, current_line_nr, false)[1] or ""
	local pattern = "%s%[" .. field_name .. ":: [^%]]*%]"

	if string.find(current_line, pattern) then
		local new_line = string.gsub(current_line, pattern, " [" .. field_name .. ":: " .. value .. "]", 1)
		vim.api.nvim_buf_set_lines(0, current_line_nr - 1, current_line_nr, false, { new_line })
	else
		local new_line = current_line .. " [" .. field_name .. ":: " .. value .. "]"
		vim.api.nvim_buf_set_lines(0, current_line_nr - 1, current_line_nr, false, { new_line })
	end
end

-- Function to add/update the completed field with today's date
local function add_completed_date()
	update_field("completion", get_current_date())
end

-- Function to add/update the date field with today's date
local function add_date_field()
	update_field("date", get_current_date())
end

-- Function to add/update the scheduled field with current datetime
local function add_scheduled_datetime()
	update_field("scheduled", get_current_datetime())
end

-- Function to add/update the due field with current datetime
local function add_due_datetime()
	update_field("due", get_current_datetime())
end

-- Function to add/update the start field with current datetime
local function add_start_datetime()
	update_field("start", get_current_datetime())
end

-- Function to toggle task status between "- " and "- [ ] "
local function toggle_task_status()
	local current_line_nr = vim.api.nvim_win_get_cursor(0)[1]
	local current_line = vim.api.nvim_buf_get_lines(0, current_line_nr - 1, current_line_nr, false)[1] or ""

	-- Pattern to match "- " at the beginning of the line (with possible whitespace before the dash)
	local unchecked_pattern = "^(%s*)%-([ ])"
	-- Pattern to match "- [x] " where x can be any character
	local checked_pattern = "^(%s*)%-%s%[(.?)%]%s"

	local new_line

	if current_line:match(checked_pattern) then
		-- If it's checked, make it unchecked
		new_line = current_line:gsub(checked_pattern, "%1- ")
	elseif current_line:match(unchecked_pattern) then
		-- If it's unchecked, make it checked with a space inside brackets
		new_line = current_line:gsub(unchecked_pattern, "%1- [ ] ")
	else
		-- If it doesn't match either pattern, do nothing
		return
	end

	vim.api.nvim_buf_set_lines(0, current_line_nr - 1, current_line_nr, false, { new_line })
end

-- Function to add or update task status with next character input
local function add_task_status_with_next_char()
	-- Set up a one-time keypress handler
	vim.api.nvim_set_keymap("n", "<Plug>GetNextChar", "", {
		callback = function()
			-- Get the character that was pressed
			local char = vim.fn.getcharstr()

			local current_line_nr = vim.api.nvim_win_get_cursor(0)[1]
			local current_line = vim.api.nvim_buf_get_lines(0, current_line_nr - 1, current_line_nr, false)[1] or ""

			-- Check if line already has a task status
			local has_status = current_line:match("^%s*%-%s%[.?%]%s")

			if has_status then
				-- Replace existing status
				local new_line = current_line:gsub("^(%s*%-%s)%[.?%](%s)", "%1[" .. char .. "]%2")
				vim.api.nvim_buf_set_lines(0, current_line_nr - 1, current_line_nr, false, { new_line })
			else
				-- Pattern to match "- " at the beginning of the line (with possible whitespace before the dash)
				local task_pattern = "^(%s*)%-(%s)"

				if current_line:match(task_pattern) then
					-- Add new status
					local new_line = current_line:gsub(task_pattern, "%1- [" .. char .. "] ")
					vim.api.nvim_buf_set_lines(0, current_line_nr - 1, current_line_nr, false, { new_line })
				end
			end

			-- Clean up the temporary mapping
			vim.api.nvim_del_keymap("n", "<Plug>GetNextChar")
		end,
		noremap = true,
		silent = true,
	})

	-- Prompt user for the next character
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Plug>GetNextChar", true, true, true), "n", false)
	vim.notify("Press a key to use as task status", vim.log.levels.INFO)
end

-- Function to toggle the "inbox" tag in YAML frontmatter
local function toggle_inbox_tag_in_yaml()
	-- Get the buffer content
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	-- Find the YAML frontmatter boundaries
	local start_idx, end_idx
	for i, line in ipairs(lines) do
		if line:match("^%-%-%-$") then
			if not start_idx then
				start_idx = i
			else
				end_idx = i
				break
			end
		end
	end

	if not start_idx or not end_idx then
		vim.notify("No valid YAML frontmatter found", vim.log.levels.WARN)
		return
	end

	-- Check if tags section exists and if inbox tag exists
	local tags_section_start = nil
	local has_inbox = false
	local tags_lines = {}
	local is_array_format = false
	local is_single_value = false
	local indent_level = ""

	for i = start_idx + 1, end_idx - 1 do
		local line = lines[i]

		-- Check for single-line format (tags: inbox)
		if line:match("^tags:%s+inbox%s*$") then
			tags_section_start = i
			has_inbox = true
			is_single_value = true
			break
		end

		-- Check for tags: line
		if line:match("^tags:%s*$") then
			tags_section_start = i
			is_array_format = true

			-- Look ahead to determine indentation style
			if i + 1 <= end_idx - 1 then
				local next_line = lines[i + 1]
				local indent = next_line:match("^(%s*)%-")
				if indent then
					indent_level = indent
				end
			end
		-- Check for array items if we're in the tags section
		elseif tags_section_start and is_array_format then
			-- Match any line with a dash, capturing the indentation
			local line_indent, rest = line:match("^(%s*)%-(.*)$")
			if line_indent then
				-- Update indent level if we haven't set it yet
				if indent_level == "" then
					indent_level = line_indent
				end

				table.insert(tags_lines, i)

				-- Check if this line has the inbox tag
				if rest:match("^%s*inbox%s*$") then
					has_inbox = true
				end
			-- If we hit a non-tag line after the tags section started, we're done
			elseif not line:match("^%s*$") then
				break
			end
		end
	end

	-- Toggle inbox tag
	if has_inbox then
		-- Remove inbox tag
		if is_single_value then
			-- Replace single value with empty array
			lines[tags_section_start] = "tags:"
			vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
			vim.notify("Removed 'inbox' tag", vim.log.levels.INFO)
		elseif is_array_format then
			-- Find and remove the inbox line
			for _, line_idx in ipairs(tags_lines) do
				local line = lines[line_idx]
				if line:match("^%s*-%s*inbox%s*$") then
					table.remove(lines, line_idx)
					vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
					vim.notify("Removed 'inbox' tag", vim.log.levels.INFO)
					break
				end
			end
		end
	else
		-- Add inbox tag
		if tags_section_start then
			if is_array_format then
				-- Add as first item in the array using the detected indentation
				local new_line = indent_level .. "- inbox"
				table.insert(lines, tags_section_start + 1, new_line)
				vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
				vim.notify("Added 'inbox' tag", vim.log.levels.INFO)
			else
				-- Convert single-line to array format
				-- If we don't have an indent level yet, use 2 spaces as default
				if indent_level == "" then
					indent_level = "  "
				end

				lines[tags_section_start] = "tags:"
				table.insert(lines, tags_section_start + 1, indent_level .. "- inbox")
				vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
				vim.notify("Added 'inbox' tag", vim.log.levels.INFO)
			end
		else
			-- Create new tags section
			-- Default to 2 spaces if we don't have an indent level
			if indent_level == "" then
				indent_level = "  "
			end

			table.insert(lines, end_idx, "tags:")
			table.insert(lines, end_idx + 1, indent_level .. "- inbox")
			vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
			vim.notify("Created tags section with 'inbox' tag", vim.log.levels.INFO)
		end
	end
end

-- Function to toggle the "inbox" tag in the current line
local function toggle_inline_inbox_tag()
	local current_line_nr = vim.api.nvim_win_get_cursor(0)[1]
	local current_line = vim.api.nvim_buf_get_lines(0, current_line_nr - 1, current_line_nr, false)[1] or ""

	-- Check if the line already has an inbox tag
	if current_line:match("%[tag:: inbox%]") then
		-- Remove the inbox tag
		local new_line = current_line:gsub("%s*%[tag:: inbox%]", "")
		vim.api.nvim_buf_set_lines(0, current_line_nr - 1, current_line_nr, false, { new_line })
		vim.notify("Removed inline 'inbox' tag", vim.log.levels.INFO)
	else
		-- Add the inbox tag
		local new_line = current_line .. " [tag:: inbox]"
		vim.api.nvim_buf_set_lines(0, current_line_nr - 1, current_line_nr, false, { new_line })
		vim.notify("Added inline 'inbox' tag", vim.log.levels.INFO)
	end
end

-- Setup function to create keymaps for markdown files
local function setup_markdown_keymaps()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "markdown",
		callback = function()
			-- Date field keymaps
			vim.keymap.set("n", "<leader>csc", add_completed_date, { buffer = true, desc = "Add Completed Date" })
			vim.keymap.set("n", "<leader>csd", add_date_field, { buffer = true, desc = "Add Date Field" })
			vim.keymap.set(
				"n",
				"<leader>css",
				add_scheduled_datetime,
				{ buffer = true, desc = "Add Scheduled Datetime" }
			)
			vim.keymap.set("n", "<leader>csu", add_due_datetime, { buffer = true, desc = "Add Due Datetime" })
			vim.keymap.set("n", "<leader>cst", add_start_datetime, { buffer = true, desc = "Add Start Datetime" })

			-- Task status keymaps
			vim.keymap.set("n", "<leader>ct", toggle_task_status, { buffer = true, desc = "Toggle Task Status" })
			vim.keymap.set(
				"n",
				"<leader>cn",
				add_task_status_with_next_char,
				{ buffer = true, desc = "Add Task Status with Next Char" }
			)

			-- Tag keymaps
			vim.keymap.set(
				"n",
				"<leader>ci",
				toggle_inline_inbox_tag,
				{ buffer = true, desc = "Toggle Inline Inbox Tag" }
			)
			vim.keymap.set(
				"n",
				"<leader>cy",
				toggle_inbox_tag_in_yaml,
				{ buffer = true, desc = "Toggle Inbox Tag in YAML" }
			)
		end,
	})
end

-- Initialize the keymaps
setup_markdown_keymaps()
