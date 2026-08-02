-- Runs a repository's bootstrap build (see `java_projects.lua`).
--
-- Shared by `:JavaBootstrap` and the automatic path in `ftplugin/java.lua` so
-- both behave identically: same command, same environment, same re-import
-- afterwards. They differ only in how the output is presented.

local M = {}

-- Checkouts with a build currently running, keyed by root:
--   { started = os.time(), last = "most recent output line" }
M.running = {}

---@param root string
---@return string?
function M.status(root)
	local job = M.running[root]
	if not job then
		return nil
	end

	local elapsed = os.time() - job.started
	local line = ("running for %dm%02ds"):format(math.floor(elapsed / 60), elapsed % 60)
	if job.last then
		line = line .. " - " .. job.last
	end
	return line
end

local function notify(message, level)
	vim.notify(message, level or vim.log.levels.INFO, { title = "Java" })
end

---@param root string
---@return table?
local function progress_handle(root)
	local ok, progress = pcall(require, "fidget.progress")
	if not ok then
		return nil
	end

	return progress.handle.create({
		title = "bootstrap",
		message = "starting",
		lsp_client = { name = require("jdtls_env").repo_name(root) or "java" },
		percentage = nil,
	})
end

local function finish(root, code, output)
	local job = M.running[root]
	M.running[root] = nil

	if code ~= 0 then
		if job and job.handle then
			job.handle:report({ message = ("failed (exit %d)"):format(code) })
			job.handle:cancel()
		end
		local tail = table.concat(vim.list_slice(output, math.max(1, #output - 12)), "\n")
		return notify(("Bootstrap failed (exit %d).\n%s"):format(code, tail), vim.log.levels.ERROR)
	end

	if job and job.handle then
		job.handle:report({ message = "done, re-importing" })
		job.handle:finish()
	end

	require("jdtls_env").warned[root] = nil

	for _, client in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
		if client.config.root_dir == root then
			client:notify("java/projectConfigurationUpdate", {
				uri = require("jdtls_env").project_build_uri(root),
			})
		end
	end
end

---@param root string
---@param bootstrap table
---@param opts? { visible?: boolean }
function M.run(root, bootstrap, opts)
	opts = opts or {}

	if M.running[root] then
		return notify("A bootstrap is already running for this checkout.", vim.log.levels.WARN)
	end
	M.running[root] = { started = os.time(), handle = progress_handle(root) }

	local job = {
		cwd = root,
		env = { MISE_TRUSTED_CONFIG_PATHS = root },
	}

	local function record(line)
		local state = M.running[root]
		if not state then
			return
		end

		local text = vim.trim(line:gsub(".*\r", ""):gsub("%c%[[%d;]*%a", ""))
		if text == "" or text:match("^<%-+>") then
			return
		end

		state.last = text
		if state.handle then
			state.handle:report({ message = text:sub(1, 60) })
		end
	end

	if opts.visible then
		vim.cmd("botright 18split | enew")
		vim.bo.bufhidden = "wipe"
		job.term = true
		job.on_exit = function(_, code)
			finish(root, code, {})
		end
	else
		local output = {}
		local function collect(_, data)
			for _, line in ipairs(data or {}) do
				if line ~= "" then
					table.insert(output, line)
					record(line)
				end
			end
		end
		job.on_stdout, job.on_stderr = collect, collect
		job.on_exit = function(_, code)
			finish(root, code, output)
		end
	end

	vim.fn.jobstart(bootstrap.cmd, job)
end

return M
