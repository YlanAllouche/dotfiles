-- Function to open a link under cursor
local function open_link_under_cursor()
	local line = vim.fn.getline(".")
	local col = vim.fn.col(".")

	-- Function to check if cursor is within a range
	local function cursor_in_range(start_idx, end_idx)
		return col >= start_idx and col <= end_idx
	end

	-- Check for wiki-style links [[target|name]]
	for start_idx, content, end_idx in string.gmatch(line, "()%[%[([^%]]+)%]%]()") do
		-- Convert string indices to numbers
		start_idx = tonumber(start_idx)
		end_idx = tonumber(end_idx)

		-- Calculate the actual character positions
		local real_start = start_idx
		local real_end = end_idx - 1

		if cursor_in_range(real_start, real_end) then
			-- Extract target from [[target|name]] or just [[target]]
			local target = string.match(content, "^([^|]+)")
			if target then
				-- Check if there's a line number specified with a colon
				local file_target, line_num
				if string.match(target, ":") then
					file_target, line_num = string.match(target, "^(.+):(%d+)$")
					line_num = tonumber(line_num)

					if file_target and line_num then
						-- vim.notify( "Found wiki link with line number: " .. file_target .. " (line " .. line_num .. ")", vim.log.levels.INFO)
						target = file_target
					else
						-- vim.notify("Found wiki link: " .. target, vim.log.levels.INFO)
					end
				else
					-- vim.notify("Found wiki link: " .. target, vim.log.levels.INFO)
				end

				-- Add .md extension if none provided
				if not string.match(target, "%.%w+$") then
					target = target .. ".md"
				end

				-- Use find command to locate the file
				local cmd = string.format("find ~/share -type f -name '%s' 2>/dev/null", target)
				local handle = io.popen(cmd)
				if handle then
					local result = handle:read("*a")
					handle:close()

					local file_path = string.match(result, "([^\n]+)")
					if file_path and file_path ~= "" then
						-- Open the file
						vim.cmd("edit " .. vim.fn.fnameescape(file_path))

						-- If line number was specified, jump to that line
						if line_num then
							vim.cmd(tostring(line_num))
							vim.cmd("normal! zz") -- Center the view on the line
						end

						return
					else
						vim.notify("File not found: " .. target, vim.log.levels.WARN)
						return
					end
				end
			end
		end
	end

	-- Check for standard markdown links [text](target)
	for start_idx, link_text, mid_idx, link_target, end_idx in string.gmatch(line, "()%[([^%]]+)%]()%(([^%)]+)%)()") do
		-- Convert string indices to numbers
		start_idx = tonumber(start_idx)
		mid_idx = tonumber(mid_idx)
		end_idx = tonumber(end_idx)

		-- Calculate the actual character positions
		local real_start = start_idx
		local real_end = end_idx - 1

		if cursor_in_range(real_start, real_end) then
			if string.match(link_target, "^https?://") then
				-- vim.notify("Opening URL: " .. link_target, vim.log.levels.INFO)
				vim.fn.jobstart({ "xdg-open", link_target })
				return
			else
				-- Check if there's a line number specified with a colon
				local file_target, line_num
				if string.match(link_target, ":") then
					file_target, line_num = string.match(link_target, "^(.+):(%d+)$")
					line_num = tonumber(line_num)
				else
					file_target = link_target
				end

				-- vim.notify("Opening file: " .. file_target, vim.log.levels.INFO)
				vim.cmd("edit " .. vim.fn.fnameescape(file_target))

				-- If line number was specified, jump to that line
				if line_num then
					vim.cmd(tostring(line_num))
					vim.cmd("normal! zz") -- Center the view on the line
				end

				return
			end
		end
	end

	-- If no link was found/opened, perform default Enter behavior
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false)
end

-- Create an autocommand group for our mappings
vim.api.nvim_create_augroup("MarkdownLinkMappings", { clear = true })

-- Set up mappings only for markdown files
vim.api.nvim_create_autocmd("FileType", {
	group = "MarkdownLinkMappings",
	pattern = "markdown",
	callback = function()
		-- Map gx to our function
		vim.keymap.set("n", "gx", open_link_under_cursor, {
			noremap = true,
			silent = true,
			buffer = true, -- Make this mapping buffer-local
			desc = "Open link under cursor",
		})

		-- Map Enter in normal mode to our function
		vim.keymap.set("n", "<CR>", open_link_under_cursor, {
			noremap = true,
			silent = true,
			buffer = true, -- Make this mapping buffer-local
			desc = "Open link under cursor",
		})

		-- vim.notify("Markdown link mappings activated", vim.log.levels.INFO)
	end,
})
