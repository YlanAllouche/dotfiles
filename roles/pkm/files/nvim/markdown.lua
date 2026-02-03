local function play_markdown_id()
	if vim.bo.filetype ~= "markdown" then
		print("Not a markdown file")
		return
	end

	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local frontmatter = {}
	local in_frontmatter = false

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

	if not frontmatter.id then
		print("No 'id' found in frontmatter")
		return
	end

	vim.fn.jobstart({ "/home/ylan/.local/bin/jelly_play_yt", frontmatter.locator }, {
		on_exit = function(_, code)
			if code == 0 then
			else
				print("Error playing: " .. frontmatter.id)
			end
		end,
	})
end

local function open_workspace()
	if vim.bo.filetype ~= "markdown" then
		print("Not a markdown file")
		return
	end

	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local frontmatter = {}
	local in_frontmatter = false

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

	if not frontmatter.workspace_path then
		print("No 'workspace_path' found in frontmatter")
		return
	end

	local full_path = vim.fn.expand("~/workspaces/" .. frontmatter.workspace_path)

	vim.fn.jobstart({ "tmux-sessionizer", full_path }, {
		on_exit = function(_, code)
			if code == 0 then
			else
				print("Error opening workspace: " .. full_path)
			end
		end,
	})
end

local function copy_backlink()
	if vim.bo.filetype ~= "markdown" then
		print("Not a markdown file")
		return
	end

	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local frontmatter = {}
	local in_frontmatter = false

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

	if not frontmatter.id then
		print("No 'id' found in frontmatter")
		return
	end
	if not frontmatter.title then
		print("No 'title' found in frontmatter")
		return
	end

	local backlink = string.format("[[%s|%s]]", frontmatter.id, frontmatter.title)

	vim.fn.setreg("+", backlink)
	vim.fn.setreg("*", backlink)

	print("Copied to clipboard: " .. backlink)
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.keymap.set("n", "<leader>bp", play_markdown_id, { buffer = true })
		vim.keymap.set("n", "<leader>bw", open_workspace, { buffer = true })
		vim.keymap.set("n", "<leader>by", copy_backlink, { buffer = true })
	end,
})
