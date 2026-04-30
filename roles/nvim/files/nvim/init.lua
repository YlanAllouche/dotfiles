vim.g.mapleader = " " -- Set leader key to space
vim.g.maplocalleader = ";" -- Set local leader key to comma

vim.o.exrc = true

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end

vim.opt.rtp:prepend(lazypath)

-- require("vim-options")
require("lazy").setup("plugins")
local function require_all(directory)
	local scan = require("plenary.scandir")
	local path = vim.fn.stdpath("config") .. "/lua/" .. directory

	-- Get all Lua files recursively
	local files = scan.scan_dir(path, {
		depth = 5,
		search_pattern = "%.lua$",
	})

	for _, file in ipairs(files) do
		-- Convert file path to require path
		local require_path = file:gsub(vim.fn.stdpath("config") .. "/lua/", ""):gsub("%.lua$", ""):gsub("/", ".")
		-- Skip init files as they are usually required by their parent module
		if not require_path:find("init$") then
			local ok, _ = pcall(require, require_path)
			if not ok then
				vim.notify("Failed to load " .. require_path, vim.log.levels.ERROR)
			end
		end
	end
end

-- Usage example:
require_all("config") -- This will require all Lua files in the plugins directory
local signs = {
	Error = "✖ ",
	Warn = "⚠ ",
	Hint = "󱐋 ",
	Info = "󰋼 ",
}

local signConf = {
	text = {},
	texthl = {},
	numhl = {},
}

for type, icon in pairs(signs) do
	local severityName = string.upper(type)
	local severity = vim.diagnostic.severity[severityName]
	local hl = "DiagnosticSign" .. type
	signConf.text[severity] = icon
	signConf.texthl[severity] = hl
	signConf.numhl[severity] = hl
end

vim.diagnostic.config({
	signs = signConf,
})
-- --------------------------------
-- --------------------------------
-- --------------------------------
-- --------------------------------
-- Load the ansible testing module
local ansible_test = require("ansible-quick-test")

-- Key mappings
vim.keymap.set("n", "<leader>ar", ansible_test.test_role, {
	desc = "Test entire Ansible role",
})

vim.keymap.set("n", "<leader>af", ansible_test.test_file, {
	desc = "Test current Ansible file",
})

-- Optional: Add which-key descriptions if you use which-key.nvim
local wk_ok, wk = pcall(require, "which-key")
if wk_ok then
	wk.register({
		["<leader>a"] = {
			name = "Ansible",
			r = "Test Role",
			f = "Test File",
		},
	})
end
