local function setup_bookmark_picker()
	local telescope_ok, telescope = pcall(require, "telescope")
	if not telescope_ok then
		vim.notify("Telescope not available", vim.log.levels.ERROR)
		return
	end

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")

	local function capitalize_words(str)
		return (str:gsub("%w+", function(w)
			return (w:sub(1, 1):upper() .. w:sub(2))
		end))
	end

	local function transform_filename(filename)
		-- Remove extension
		local name = filename:match("([^.]*)")
		-- Replace dashes with spaces
		name = name:gsub("-", " ")
		-- Capitalize each word
		name = capitalize_words(name)
		return name
	end

	local function list_bookmark_files()
		local dir = vim.fn.expand("~/share/_tmp")
		local files = vim.fn.readdir(dir)
		local json_files = {}
		for _, file in ipairs(files) do
			if file:match("%.json$") then
				local full_path = dir .. "/" .. file
				table.insert(json_files, {
					filename = file,
					display = transform_filename(file),
					path = full_path,
				})
			end
		end
		return json_files
	end

	local function bookmark_picker()
		local files = list_bookmark_files()
		local entries = {}
		for _, file in ipairs(files) do
			table.insert(entries, {
				value = file.filename,
				display = file.display,
				path = file.path,
			})
		end

		pickers
			.new({}, {
				prompt_title = "Bookmark Files",
				finder = finders.new_table({
					results = entries,
					entry_maker = function(entry)
						return {
							value = entry.value,
							display = entry.display,
							ordinal = entry.display,
							path = entry.path,
						}
					end,
				}),
				sorter = conf.generic_sorter({}),
				attach_mappings = function(prompt_bufnr, map)
					actions.select_default:replace(function()
						actions.close(prompt_bufnr)
						local selection = require("telescope.actions.state").get_selected_entry()
						if selection and selection.path then
							local file_path = vim.fn.expand(selection.path) -- Expand path again
							-- Debugging: Print the file path to the console
							print("Attempting to open bookmark file: " .. file_path)
							if vim.fn.filereadable(file_path) == 1 then
								vim.cmd("BookmarkList " .. file_path)
							else
								vim.notify("File not readable: " .. file_path, vim.log.levels.ERROR)
							end
						else
							vim.notify("No file selected.", vim.log.levels.WARN)
						end
					end)
					return true
				end,
			})
			:find()
	end

	-- Register the Bookmark Picker command
	vim.api.nvim_create_user_command("BookmarkPicker", bookmark_picker, {})

	-- Set the keybinding
	vim.keymap.set("n", "<C-z>", ":BookmarkPicker<CR>", { noremap = true, silent = true })

	-- vim.notify("Bookmark picker feature is ready", vim.log.levels.INFO)
end

vim.defer_fn(setup_bookmark_picker, 100)

---------------------
-- Example shortcut to open a specific bookmark file
vim.keymap.set("n", "<leader>bv", function()
	vim.cmd("BookmarkList " .. vim.fn.expand("~/share/_tmp/-main.json"))
end, { noremap = true, silent = true })

-- Or if you have multiple bookmark files, you can create different shortcuts
vim.keymap.set("n", "<leader>bb", function()
	vim.cmd("BookmarkList " .. vim.fn.expand("~/share/_tmp/-secondary.json"))
end, { noremap = true, silent = true })

vim.keymap.set("n", "<leader>bc", function()
	vim.cmd("BookmarkList " .. vim.fn.expand("~/share/_tmp/-all.json"))
end, { noremap = true, silent = true })
