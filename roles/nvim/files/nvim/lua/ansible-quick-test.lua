-- ~/.config/nvim/lua/ansible-quick-test.lua

local M = {}

-- Helper function to get current buffer path
local function get_current_path()
	return vim.fn.expand("%:p")
end

-- Helper function to find role directory
local function find_role_dir(path)
	local dir = vim.fn.fnamemodify(path, ":h")
	while dir ~= "/" do
		-- Check if current directory has tasks/main.yml or meta/main.yml (role indicators)
		if vim.fn.filereadable(dir .. "/tasks/main.yml") == 1 or vim.fn.filereadable(dir .. "/meta/main.yml") == 1 then
			return dir
		end
		dir = vim.fn.fnamemodify(dir, ":h")
	end
	return nil
end

-- Helper function to find inventory file (updated for nested directories)
local function find_inventory_file(start_dir)
	local common_inventory_names = {
		"inventory.yml",
		"inventory.yaml",
		"hosts.yml",
		"hosts.yaml",
		"inventory",
		"hosts",
		"inventory.ini",
	}

	local common_inventory_dirs = {
		"inventory",
		"inventories",
		"inv",
	}

	local dir = start_dir
	while dir ~= "/" do
		-- Check for inventory files directly in directory
		for _, name in ipairs(common_inventory_names) do
			local inventory_path = dir .. "/" .. name
			if vim.fn.filereadable(inventory_path) == 1 then
				return inventory_path
			end
		end

		-- Check for inventory files in subdirectories
		for _, inv_dir in ipairs(common_inventory_dirs) do
			local inv_dir_path = dir .. "/" .. inv_dir
			if vim.fn.isdirectory(inv_dir_path) == 1 then
				for _, name in ipairs(common_inventory_names) do
					local inventory_path = inv_dir_path .. "/" .. name
					if vim.fn.filereadable(inventory_path) == 1 then
						return inventory_path
					end
				end
			end
		end

		dir = vim.fn.fnamemodify(dir, ":h")
	end
	return nil
end

-- Helper function to get target host and determine connection type
local function get_target_details()
	local hostname_test = vim.fn.getenv("hostname_test")

	if hostname_test ~= vim.NIL and hostname_test ~= "" then
		return hostname_test, "ssh"
	else
		return "localhost", "local"
	end
end

-- Helper function to run ansible command in terminal
local function run_ansible_command(cmd)
	-- Open a new terminal split and run the command
	vim.cmd("split")
	vim.cmd("terminal")
	vim.fn.chansend(vim.b.terminal_job_id, cmd .. "\n")
end

-- Test entire role
function M.test_role()
	local current_path = get_current_path()
	local role_dir = find_role_dir(current_path)

	if not role_dir then
		vim.notify("Not in an Ansible role directory!", vim.log.levels.ERROR)
		return
	end

	local role_name = vim.fn.fnamemodify(role_dir, ":t")
	local target_host, connection = get_target_details()

	-- Find inventory file
	local inventory_file = nil
	if connection == "ssh" then
		inventory_file = find_inventory_file(role_dir)
		if not inventory_file then
			vim.notify(
				"No inventory file found! Please create inventory.yml or inventory/hosts.yml",
				vim.log.levels.ERROR
			)
			return
		end
	end

	local playbook = string.format(
		[[
---
- hosts: %s
  connection: %s
  roles:
    - %s]],
		target_host,
		connection,
		role_dir
	)

	-- Create temporary playbook file
	local temp_playbook = vim.fn.tempname() .. ".yml"
	local file = io.open(temp_playbook, "w")
	file:write(playbook)
	file:close()

	local cmd
	if inventory_file then
		cmd = string.format(
			"cd %s && ansible-playbook -i %s %s --check --diff -v; rm %s",
			role_dir,
			inventory_file,
			temp_playbook,
			temp_playbook
		)
	else
		cmd = string.format(
			"cd %s && ansible-playbook %s --check --diff -v; rm %s",
			role_dir,
			temp_playbook,
			temp_playbook
		)
	end

	local inventory_info = inventory_file and string.format(" (using %s)", vim.fn.fnamemodify(inventory_file, ":t"))
		or ""
	vim.notify(string.format("Testing role '%s' on '%s'%s", role_name, target_host, inventory_info))
	run_ansible_command(cmd)
end

-- Test single file
function M.test_file()
	local current_path = get_current_path()
	local role_dir = find_role_dir(current_path)

	if not role_dir then
		vim.notify("Not in an Ansible role directory!", vim.log.levels.ERROR)
		return
	end

	-- Get current file content
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local file_content = table.concat(lines, "\n")

	local target_host, connection = get_target_details()

	-- Find inventory file
	local inventory_file = nil
	if connection == "ssh" then
		inventory_file = find_inventory_file(role_dir)
		if not inventory_file then
			vim.notify(
				"No inventory file found! Please create inventory.yml or inventory/hosts.yml",
				vim.log.levels.ERROR
			)
			return
		end
	end

	-- Determine if current file is a playbook or tasks file
	local is_playbook = string.match(file_content, "^%s*%-%-%-%s*$") and string.match(file_content, "hosts%s*:")

	local playbook
	if is_playbook then
		-- File is already a playbook, use it directly but update host if needed
		playbook = string.gsub(file_content, "hosts%s*:%s*[^\n]*", "hosts: " .. target_host)
		-- Also update connection if specified
		if not string.match(playbook, "connection%s*:") then
			playbook = string.gsub(playbook, "(hosts%s*:[^\n]*\n)", "%1  connection: " .. connection .. "\n")
		else
			playbook = string.gsub(playbook, "connection%s*:%s*[^\n]*", "connection: " .. connection)
		end
	else
		-- File contains tasks, wrap it in a playbook
		-- Remove leading --- if present and clean up the content
		local cleaned_content = string.gsub(file_content, "^%s*%-%-%-%s*\n?", "")

		playbook = string.format(
			[[
---
- hosts: %s
  connection: %s
  tasks:
%s]],
			target_host,
			connection,
			-- Indent each line by 4 spaces, but handle empty lines properly
			string.gsub(cleaned_content, "([^\n]*)", function(line)
				if line:match("^%s*$") then
					return line -- Keep empty lines as-is
				else
					return "    " .. line -- Indent non-empty lines
				end
			end)
		)
	end

	-- Create temporary playbook file
	local temp_playbook = vim.fn.tempname() .. ".yml"
	local file = io.open(temp_playbook, "w")
	file:write(playbook)
	file:close()

	local cmd
	if inventory_file then
		cmd = string.format(
			"cd %s && ansible-playbook -i %s %s --check --diff -v; rm %s",
			role_dir,
			inventory_file,
			temp_playbook,
			temp_playbook
		)
	else
		cmd = string.format(
			"cd %s && ansible-playbook %s --check --diff -v; rm %s",
			role_dir,
			temp_playbook,
			temp_playbook
		)
	end

	local filename = vim.fn.expand("%:t")
	local inventory_info = inventory_file and string.format(" (using %s)", vim.fn.fnamemodify(inventory_file, ":t"))
		or ""
	vim.notify(string.format("Testing file '%s' on '%s'%s", filename, target_host, inventory_info))
	run_ansible_command(cmd)
end

return M
