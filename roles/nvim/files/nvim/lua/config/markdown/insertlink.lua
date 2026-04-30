local function setup_focus_links()
	local telescope_ok, telescope = pcall(require, "telescope")
	if not telescope_ok then
		vim.notify("Telescope not available", vim.log.levels.ERROR)
		return
	end

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	local function insert_focus_link()
		-- Path to the focus.json file
		local focus_file_path = vim.fn.expand("~/share/_tmp/topics-and-researchs.json")

		-- Read the focus.json file
		local file = io.open(focus_file_path, "r")
		if not file then
			vim.notify("Could not open topics-and-researchs.json file", vim.log.levels.ERROR)
			return
		end

		local content = file:read("*all")
		file:close()

		-- Parse the JSON content
		local status, focus_data = pcall(vim.json.decode, content)
		if not status then
			vim.notify("Error parsing topics-and-researchs.json: " .. focus_data, vim.log.levels.ERROR)
			return
		end

		-- Prepare entries for telescope
		local entries = {}
		for _, item in ipairs(focus_data) do
			if item.type == "file" and item.file and item.summary then
				-- Extract UUID from the file path (filename without extension)
				local uuid = item.file:match("([^/]+)%.md$")

				table.insert(entries, {
					file_path = item.file,
					full_path = vim.fn.expand("~/share/" .. item.file),
					summary = item.summary,
					uuid = uuid,
					display = item.summary .. " (" .. item.file .. ")",
				})
			end
		end

		-- Create telescope picker
		pickers
			.new({}, {
				prompt_title = "Focus Items",
				finder = finders.new_table({
					results = entries,
					entry_maker = function(entry)
						return {
							value = entry,
							display = entry.display,
							ordinal = entry.summary .. " " .. entry.file_path,
							path = entry.full_path,
						}
					end,
				}),
				sorter = conf.generic_sorter({}),
				attach_mappings = function(prompt_bufnr, map)
					actions.select_default:replace(function()
						actions.close(prompt_bufnr)
						local selection = action_state.get_selected_entry()
						if selection and selection.value then
							-- Insert the markdown link in the format [[uuid|title]]
							local link = "[[" .. selection.value.uuid .. "|" .. selection.value.summary .. "]]"
							vim.api.nvim_put({ link }, "", false, true)
						else
							vim.notify("No item selected", vim.log.levels.WARN)
						end
					end)
					return true
				end,
			})
			:find()
	end

	-- Register the command
	vim.api.nvim_create_user_command("FocusLink", insert_focus_link, {})

	-- Set the keybinding (Ctrl+i)
	vim.keymap.set("n", "<C-S-i>", ":FocusLink<CR>", { noremap = true, silent = true })
	vim.keymap.set("i", "<C-S-i>", "<Cmd>FocusLink<CR>", { noremap = true, silent = true })

	-- vim.notify("Focus links feature is ready", vim.log.levels.INFO)
end

vim.defer_fn(setup_focus_links, 100)
