local function play_markdown_id()
	-- Check if the current buffer is a markdown file
	if vim.bo.filetype ~= "markdown" then
		print("Not a markdown file")
		return
	end

	-- Read the entire buffer content
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local frontmatter = {}
	local in_frontmatter = false

	-- Parse frontmatter
	for _, line in ipairs(lines) do
		if line:match("^---") then
			if not in_frontmatter then
				in_frontmatter = true
			else
				break
			end
		elseif in_frontmatter then
			local key, value = line:match("^(%w+):%s*(.+)$")
			if key and value then
				frontmatter[key] = value:gsub('^"', ""):gsub('"$', "")
			end
		end
	end

	-- Check if 'id' exists in frontmatter
	if not frontmatter.id then
		print("No 'id' found in frontmatter")
		return
	end

	-- Async job to run the command
	vim.fn.jobstart({ vim.fn.expand("~/.local/bin/jelly_play_yt"), frontmatter.locator }, {
		on_exit = function(_, code)
			if code == 0 then
				-- print("Successfully played: " .. frontmatter.id)
			else
				print("Error playing: " .. frontmatter.id)
			end
		end,
	})
end

local function open_workspace()
	-- Check if the current buffer is a markdown file
	if vim.bo.filetype ~= "markdown" then
		print("Not a markdown file")
		return
	end

	-- Read the entire buffer content
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local frontmatter = {}
	local in_frontmatter = false

	-- Parse frontmatter
	for _, line in ipairs(lines) do
		if line:match("^---") then
			if not in_frontmatter then
				in_frontmatter = true
			else
				break
			end
		elseif in_frontmatter then
			-- Updated pattern to handle underscores in key names
			local key, value = line:match("^([%w_]+):%s*(.+)$")
			if key and value then
				frontmatter[key] = value:gsub('^"', ""):gsub('"$', "")
			end
		end
	end

	-- Check if 'workspace_path' exists in frontmatter
	if not frontmatter.workspace_path then
		print("No 'workspace_path' found in frontmatter")
		return
	end

	-- Construct full path from ~/workspaces/ root
	local full_path = vim.fn.expand("~/workspaces/" .. frontmatter.workspace_path)

	-- Run tmux-sessionizer with the workspace_path
	vim.fn.jobstart({ "tmux-sessionizer", full_path }, {
		on_exit = function(_, code)
			if code == 0 then
				-- print("Successfully opened workspace: " .. full_path)
			else
				print("Error opening workspace: " .. full_path)
			end
		end,
	})
end

local function copy_backlink()
	-- Check if the current buffer is a markdown file
	if vim.bo.filetype ~= "markdown" then
		print("Not a markdown file")
		return
	end

	-- Read the entire buffer content
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local frontmatter = {}
	local in_frontmatter = false

	-- Parse frontmatter
	for _, line in ipairs(lines) do
		if line:match("^---") then
			if not in_frontmatter then
				in_frontmatter = true
			else
				break
			end
		elseif in_frontmatter then
			local key, value = line:match("^([%w_]+):%s*(.+)$")
			if key and value then
				frontmatter[key] = value:gsub('^"', ""):gsub('"$', "")
			end
		end
	end

	-- Check if both 'id' and 'title' exist in frontmatter
	if not frontmatter.id then
		print("No 'id' found in frontmatter")
		return
	end
	if not frontmatter.title then
		print("No 'title' found in frontmatter")
		return
	end

	-- Construct the backlink
	local backlink = string.format("[[%s|%s]]", frontmatter.id, frontmatter.title)

	-- Copy to unnamed register (Neovim's default clipboard)
	vim.fn.setreg("+", backlink)
	vim.fn.setreg("*", backlink)

	print("Copied to clipboard: " .. backlink)
end

-- Set up the mappings only for markdown files
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.keymap.set("n", "<leader>bp", play_markdown_id, { buffer = true })
		vim.keymap.set("n", "<leader>bw", open_workspace, { buffer = true })
		vim.keymap.set("n", "<leader>by", copy_backlink, { buffer = true })
	end,
})
