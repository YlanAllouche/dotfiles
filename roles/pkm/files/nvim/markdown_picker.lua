local function setup_markdown_picker()
	local telescope_ok, telescope = pcall(require, "telescope")
	if not telescope_ok then
		vim.notify("Telescope not available", vim.log.levels.ERROR)
		return
	end

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local previewers = require("telescope.previewers")

	local markdown_dir = "~/share/"

	local function get_markdown_files()
		local files = {}
		local handle = io.popen("find " .. vim.fn.expand(markdown_dir) .. " -name '*.md'")
		if handle then
			for file in handle:lines() do
				table.insert(files, file)
			end
			handle:close()
		end
		return files
	end

	local function get_title_from_frontmatter(file_path)
		local file = io.open(file_path, "r")
		if not file then
			return ""
		end
		local content = file:read("*all")
		file:close()
		local title = content:match("title:%s*(.-)%s*\n")
		return title or ""
	end

	local function markdown_picker()
		local files = get_markdown_files()
		local items = {}
		for _, file in ipairs(files) do
			local title = get_title_from_frontmatter(file)
			table.insert(items, { title = title, path = file })
		end

		pickers
			.new({}, {
				prompt_title = "Markdown Files",
				finder = finders.new_table({
					results = items,
					entry_maker = function(entry)
						return {
							value = entry,
							display = entry.title ~= "" and entry.title or vim.fn.fnamemodify(entry.path, ":t"),
							ordinal = entry.title .. " " .. entry.path,
							path = entry.path,
						}
					end,
				}),
				sorter = conf.generic_sorter({}),
				previewer = previewers.new_buffer_previewer({
					title = "File Preview",
					define_preview = function(self, entry, status)
						local lines = {}
						for line in io.lines(entry.path) do
							table.insert(lines, line)
						end
						vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
						vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
						vim.api.nvim_buf_call(self.state.bufnr, function()
							vim.cmd("syntax enable")
						end)
					end,
				}),
				attach_mappings = function(prompt_bufnr, map)
					actions.select_default:replace(function()
						actions.close(prompt_bufnr)
						local selection = require("telescope.actions.state").get_selected_entry()
						if selection and selection.path then
							vim.cmd("edit " .. selection.path)
						else
							vim.notify("No file selected.", vim.log.levels.WARN)
						end
					end)
					return true
				end,
			})
			:find()
	end

	vim.api.nvim_create_user_command("MarkdownPicker", markdown_picker, {})

	vim.keymap.set("n", "<leader>O", ":MarkdownPicker<CR>", { noremap = true, silent = true })
end

vim.defer_fn(setup_markdown_picker, 100)
