local M = {}

-- Load and parse a data view JSON file
local function load_dataview_entries(filename)
	-- Use vim.fn.expand to properly expand tilde
	local json_path = vim.fn.expand("~/share/_tmp/" .. filename)

	-- Read the JSON file
	local file = io.open(json_path, "r")
	if not file then
		vim.notify("Could not open dataview JSON: " .. json_path, vim.log.levels.ERROR)
		return {}
	end

	local content = file:read("*all")
	file:close()

	-- Parse the JSON content
	local status, data = pcall(vim.json.decode, content)
	if not status then
		vim.notify("Error parsing dataview JSON: " .. tostring(data), vim.log.levels.ERROR)
		return {}
	end

	return data
end

-- Format entries for telescope
local function format_entries(data)
	local entries = {}
	local seen = {} -- For deduplication

	for i, entry in ipairs(data) do
		-- Strict validation - require both file AND summary
		if entry.file and entry.summary then
			-- Extract only the fields we need, ignoring all others
			local summary = tostring(entry.summary)
			local file = tostring(entry.file)
			local line = tonumber(entry.line) or 0

			-- Create unique key for deduplication
			local key = string.format("%s|%s|%d", summary, file, line)

			if not seen[key] then
				seen[key] = true
				local display_text = string.format("%s | %s:%d", summary, file, line)
				table.insert(entries, {
					display = display_text,
					summary = summary,
					file = file,
					line = line, -- 0-based line from JSON
					full_path = vim.fn.expand("~/share/" .. file),
				})
			end
		end
	end

	return entries
end

-- Create the telescope picker
local function create_picker(filename, title)
	local telescope = require("telescope")
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local sorters = require("telescope.sorters")

	local data = load_dataview_entries(filename)
	if #data == 0 then
		vim.notify("No entries found in dataview JSON", vim.log.levels.WARN)
		return
	end

	local entries = format_entries(data)

	-- Debug logging
	vim.notify(string.format("Loaded %d entries from %s", #entries, filename), vim.log.levels.INFO)

	local picker = pickers.new({}, {
		prompt_title = title or "Dataview Picker",
		sorting_strategy = "ascending", --FIX: why is this necessary to avoid the error message?
		finder = finders.new_table({
			results = entries,
			entry_maker = function(entry)
				return {
					value = entry,
					display = entry.display,
					ordinal = string.lower(entry.summary .. " " .. entry.file),
					path = entry.full_path,
				}
			end,
		}),
		previewer = conf.file_previewer({}),
		sorter = sorters.get_fzy_sorter({
			-- fzy sorter is better at substring matching and prioritizes exact matches
			case_mode = "ignore_case",
		}),
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				if selection and selection.path then
					-- Open the file
					vim.cmd("edit " .. vim.fn.fnameescape(selection.path))

					-- Jump to the line using the stored value
					-- Use vim.schedule to ensure file is loaded before jumping
					vim.schedule(function()
						local target_line = (selection.value.line or 0) + 1 -- Convert 0-based to 1-based
						local line_count = vim.api.nvim_buf_line_count(0)
						if line_count > 0 then
							target_line = math.max(1, math.min(target_line, line_count))
							pcall(vim.api.nvim_win_set_cursor, 0, { target_line, 0 })
							-- Center the cursor line
							vim.cmd("normal! zz")
						end
					end)
				else
					vim.notify("No file selected.", vim.log.levels.WARN)
				end
			end)
			return true
		end,
	})

	picker:find()
end

-- Public API
function M.open(filename, title)
	create_picker(filename, title)
end

return M
