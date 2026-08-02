-- Shared, cached environment discovery for the Eclipse JDT language server.
--
-- Kept out of `lua/config/` on purpose: `init.lua` auto-requires everything in
-- that directory at startup, while this module should only ever be loaded the
-- first time a Java buffer is opened.

local M = {}

local mason = vim.fn.stdpath("data") .. "/mason/packages"
local extra_bundles = vim.fn.stdpath("data") .. "/java-bundles"
local mise_java_installs = vim.fn.expand("~/.local/share/mise/installs/java")
local local_java_projects = vim.fn.expand("~/.local/java-projects.lua")

M.default_jdk_major = 25

M.jdtls_home = mason .. "/jdtls"
M.lombok_jar = M.jdtls_home .. "/lombok.jar"

local function execution_environment(major)
	if major <= 8 then
		return "JavaSE-1." .. major
	end
	return "JavaSE-" .. major
end

local function discover_jdks()
	local jdks = {}

	for name, type_ in vim.fs.dir(mise_java_installs) do
		if type_ == "directory" or type_ == "link" then
			local major = name:match("^%a+%-(%d+)$")
			if major then
				local home = mise_java_installs .. "/" .. name
				if vim.uv.fs_stat(home .. "/bin/java") then
					jdks[tonumber(major)] = home
				end
			end
		end
	end

	return jdks
end

local jdks_cache
function M.jdks()
	if not jdks_cache then
		jdks_cache = vim.uv.fs_stat(mise_java_installs) and discover_jdks() or {}
	end
	return jdks_cache
end

function M.runtimes()
	local jdks = M.jdks()
	local majors = vim.tbl_keys(jdks)
	table.sort(majors)

	local runtimes = {}
	for _, major in ipairs(majors) do
		table.insert(runtimes, {
			name = execution_environment(major),
			path = jdks[major],
			default = major == M.default_jdk_major,
		})
	end

	return runtimes
end

function M.jdtls_java_home()
	local override = vim.env.JDTLS_JAVA_HOME
	if override and vim.uv.fs_stat(override .. "/bin/java") then
		return override
	end

	local jdks = M.jdks()
	local candidates = vim.tbl_filter(function(major)
		return major >= 21
	end, vim.tbl_keys(jdks))

	if #candidates == 0 then
		return nil
	end

	table.sort(candidates)
	local chosen = vim.tbl_contains(candidates, M.default_jdk_major) and M.default_jdk_major or candidates[#candidates]

	return jdks[chosen]
end

function M.bundles()
	local bundles = {}

	local function add(glob)
		vim.list_extend(bundles, vim.fn.glob(glob, true, true))
	end

	add(mason .. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar")
	add(extra_bundles .. "/vscode-java-debug/extension/server/com.microsoft.java.debug.plugin-*.jar")

	local excluded = {
		["com.microsoft.java.test.runner-jar-with-dependencies.jar"] = true,
		["jacocoagent.jar"] = true,
	}

	for _, root in ipairs({ mason .. "/java-test", extra_bundles .. "/vscode-java-test" }) do
		for _, jar in ipairs(vim.fn.glob(root .. "/extension/server/*.jar", true, true)) do
			if not excluded[vim.fs.basename(jar)] then
				table.insert(bundles, jar)
			end
		end
	end

	return bundles
end

local function shipped_config_dir()
	local suffix
	if vim.fn.has("mac") == 1 then
		suffix = vim.uv.os_uname().machine == "arm64" and "config_mac_arm" or "config_mac"
	elseif vim.fn.has("win32") == 1 then
		suffix = "config_win"
	else
		suffix = vim.uv.os_uname().machine == "aarch64" and "config_linux_arm" or "config_linux"
	end

	local dir = M.jdtls_home .. "/" .. suffix
	if not vim.uv.fs_stat(dir) then
		dir = M.jdtls_home .. "/" .. suffix:gsub("_arm$", "")
	end
	return dir
end

---@param workspace string
function M.config_dir(workspace)
	local dir = workspace .. "/config"
	local ini = dir .. "/config.ini"

	if not vim.uv.fs_stat(ini) then
		vim.fn.mkdir(dir, "p")
		vim.fn.writefile(vim.fn.readfile(shipped_config_dir() .. "/config.ini"), ini)
	end

	return dir
end

function M.launcher_jar()
	return vim.fn.glob(M.jdtls_home .. "/plugins/org.eclipse.equinox.launcher_*.jar", true, true)[1]
end

---@param root string
---@return string
function M.project_build_uri(root)
	for _, name in ipairs({ "build.gradle", "build.gradle.kts", "pom.xml" }) do
		local path = root .. "/" .. name
		if vim.uv.fs_stat(path) then
			return vim.uri_from_fname(path)
		end
	end
	return vim.uri_from_fname(root)
end

---@param bufnr integer
---@return string|nil
function M.project_root(bufnr)
	local start = vim.api.nvim_buf_get_name(bufnr)
	if start == "" then
		start = vim.uv.cwd()
	end

	local function outermost(markers)
		local matches = vim.fs.find(markers, { upward = true, path = start, limit = math.huge })
		local last = matches[#matches]
		return last and vim.fs.dirname(last) or nil
	end

	local root = outermost({ "settings.gradle", "settings.gradle.kts" }) or outermost({ "pom.xml" })
	if root then
		return root
	end

	local git = vim.fs.find({ ".git" }, { upward = true, path = start })[1]
	if git then
		return vim.fs.dirname(git)
	end

	return outermost({ "build.gradle", "build.gradle.kts", "gradlew", "mvnw" })
end

local git_common_cache = {}
---@param root string
---@return string|nil
function M.git_common_dir(root)
	if git_common_cache[root] ~= nil then
		return git_common_cache[root] or nil
	end

	local resolved = false
	if vim.fn.executable("git") == 1 and vim.fn.isdirectory(root) == 1 then
		local ok, out = pcall(function()
			return vim.system({ "git", "rev-parse", "--path-format=absolute", "--git-common-dir" }, {
				cwd = root,
				text = true,
			}):wait()
		end)
		if ok and out.code == 0 then
			local dir = vim.trim(out.stdout or "")
			if dir ~= "" then
				resolved = dir
			end
		end
	end

	git_common_cache[root] = resolved
	return resolved or nil
end

---@param root string
function M.repo_name(root)
	local common = M.git_common_dir(root)
	if not common then
		return vim.fs.basename(root)
	end

	local name = vim.fs.basename(common)
	if name == ".git" then
		name = vim.fs.basename(vim.fs.dirname(common))
	end
	return (name:gsub("%.git$", ""))
end

---@param root string
---@return string
function M.workspace(root)
	root = vim.uv.fs_realpath(root) or vim.fn.fnamemodify(root, ":p")
	root = root:gsub("/$", "")

	local repo = M.repo_name(root)
	local checkout = vim.fn.fnamemodify(root, ":t")
	local dir = ("%s/jdtls/%s/%s-%s"):format(vim.fn.stdpath("cache"), repo, checkout, vim.fn.sha256(root):sub(1, 8))

	local marker = dir .. "/.jdtls-root"
	if not vim.uv.fs_stat(marker) then
		vim.fn.mkdir(dir, "p")
		vim.fn.writefile({ root }, marker)
	end

	return dir
end

---@return { dir: string, repo: string, root: string|nil, stale: boolean }[]
function M.workspaces()
	local base = vim.fn.stdpath("cache") .. "/jdtls"
	local found = {}

	for _, marker in ipairs(vim.fn.glob(base .. "/*/*/.jdtls-root", true, true)) do
		local dir = vim.fs.dirname(marker)
		local root = vim.fn.readfile(marker)[1]
		table.insert(found, {
			dir = dir,
			repo = vim.fs.basename(vim.fs.dirname(dir)),
			root = root,
			stale = not (root and vim.uv.fs_stat(root)),
			mtime = (vim.uv.fs_stat(dir) or {}).mtime,
		})
	end

	table.sort(found, function(a, b)
		return (a.mtime and a.mtime.sec or 0) > (b.mtime and b.mtime.sec or 0)
	end)

	return found
end

local function load_local_profiles()
	if not vim.uv.fs_stat(local_java_projects) then
		return {}
	end

	local chunk, err = loadfile(local_java_projects)
	if not chunk then
		vim.notify(("Failed to load %s: %s"):format(local_java_projects, err), vim.log.levels.ERROR, { title = "Java" })
		return {}
	end

	local ok, profiles = pcall(chunk)
	if not ok then
		vim.notify(("Failed to evaluate %s: %s"):format(local_java_projects, profiles), vim.log.levels.ERROR, { title = "Java" })
		return {}
	end

	return type(profiles) == "table" and profiles or {}
end

local function all_profiles()
	local profiles = {}
	local ok, builtin = pcall(require, "java_projects")
	if ok and type(builtin) == "table" then
		vim.list_extend(profiles, builtin)
	end
	vim.list_extend(profiles, load_local_profiles())
	return profiles
end

---@param root string
---@return table|nil
function M.profile(root)
	local repo = M.repo_name(root)
	for _, profile in ipairs(all_profiles()) do
		if profile.match then
			if profile.match(root) then
				return profile
			end
		elseif profile.repo_pattern then
			if repo:match("^" .. profile.repo_pattern .. "$") then
				return profile
			end
		elseif profile.repo == repo then
			return profile
		end
	end

	return nil
end

---@param root string
---@return string[]|nil, string[]
function M.classpath_gaps(root)
	local prefs = M.workspace(root) .. "/.metadata/.plugins/org.eclipse.buildship.core/project-preferences"
	local files = vim.fn.glob(prefs .. "/*", true, true)
	if #files == 0 then
		return nil, {}
	end

	local jars, seen_jar = {}, {}
	local dirs, seen_dir = {}, {}

	for _, file in ipairs(files) do
		for _, line in ipairs(vim.fn.readfile(file)) do
			for path in line:gmatch('kind\\="lib" path\\="([^"]+)"') do
				if path:sub(-4) == ".jar" and not seen_jar[path] and not vim.uv.fs_stat(path) then
					seen_jar[path] = true
					table.insert(jars, path)

					local dir = vim.fs.dirname(path)
					if dir:sub(1, #root) == root then
						dir = dir:sub(#root + 2)
					end
					if not seen_dir[dir] then
						seen_dir[dir] = true
						table.insert(dirs, dir)
					end
				end
			end
		end
	end

	table.sort(dirs)
	return jars, dirs
end

---@param root string
---@return boolean
function M.classpath_outdated(root)
	local profile = M.profile(root)
	local produces = profile and profile.bootstrap and profile.bootstrap.produces
	if not produces then
		return false
	end

	local built = vim.fn.glob(root .. "/" .. produces, true, true)[1]
	local built_stat = built and vim.uv.fs_stat(built)
	if not built_stat then
		return false
	end

	local prefs = M.workspace(root) .. "/.metadata/.plugins/org.eclipse.buildship.core/project-preferences"
	local files = vim.fn.glob(prefs .. "/*", true, true)
	if #files == 0 then
		return false
	end

	local imported = 0
	for _, file in ipairs(files) do
		local stat = vim.uv.fs_stat(file)
		if stat and stat.mtime.sec > imported then
			imported = stat.mtime.sec
		end
	end

	return built_stat.mtime.sec > imported
end

---@param root string
---@return boolean|nil, table|nil, string[]
function M.bootstrap_pending(root)
	local profile = M.profile(root)
	local bootstrap = profile and profile.bootstrap

	if bootstrap and bootstrap.produces then
		if #vim.fn.glob(root .. "/" .. bootstrap.produces, true, true) == 0 then
			return true, bootstrap, { vim.fs.dirname(bootstrap.produces) }
		end
	end

	local jars, dirs = M.classpath_gaps(root)
	if not jars then
		return nil, bootstrap, {}
	end
	return #jars > 0, bootstrap, dirs
end

M.warned = {}
M.resynced = {}

---@param root string
---@param args string[]
---@return string|nil
local function mise(root, args)
	if vim.fn.executable("mise") ~= 1 then
		return nil
	end

	local ok, out = pcall(function()
		return vim.system(vim.list_extend({ "mise" }, args), {
			cwd = root,
			text = true,
			env = { MISE_TRUSTED_CONFIG_PATHS = root },
		}):wait()
	end)
	if not ok or out.code ~= 0 then
		return nil
	end

	local value = vim.trim(out.stdout or "")
	return value ~= "" and value or nil
end
M.mise = mise

---@param root string
---@return boolean
function M.has_mise_config(root)
	for _, name in ipairs({
		"mise.toml",
		".mise.toml",
		"mise/config.toml",
		".mise/config.toml",
		".config/mise/config.toml",
		".tool-versions",
	}) do
		if vim.uv.fs_stat(root .. "/" .. name) then
			return true
		end
	end
	return false
end

---@param root string
---@return integer[]|nil
function M.project_gradle_version(root)
	local function parse(s)
		local major, minor = s:match("^(%d+)%.(%d+)")
		if major then
			return { tonumber(major), tonumber(minor) }
		end
		major = s:match("^(%d+)$")
		return major and { tonumber(major), 0 } or nil
	end

	local props = root .. "/gradle/wrapper/gradle-wrapper.properties"
	if vim.uv.fs_stat(props) then
		for _, line in ipairs(vim.fn.readfile(props)) do
			local version = line:match("distributionUrl=.*gradle%-([%d%.]+)%-")
			if version then
				return parse(version)
			end
		end
	end

	local home = M.project_gradle_home(root)
	return home and parse(vim.fs.basename(home):gsub("^gradle%-", "")) or nil
end

local GRADLE_MIN_FOR_JAVA = {
	[17] = { 7, 3 },
	[18] = { 7, 5 },
	[19] = { 7, 6 },
	[20] = { 8, 3 },
	[21] = { 8, 5 },
	[22] = { 8, 8 },
	[23] = { 8, 10 },
	[24] = { 8, 14 },
	[25] = { 9, 1 },
	[26] = { 9, 4 },
}

---@param a integer[]
---@param b integer[]
---@return boolean
local function at_least(a, b)
	if a[1] ~= b[1] then
		return a[1] > b[1]
	end
	return a[2] >= b[2]
end

---@param root string
---@return string|nil
function M.gradle_compatible_java_home(root)
	local gradle = M.project_gradle_version(root)
	if not gradle then
		return nil
	end

	local best, best_major
	for major, path in pairs(M.jdks()) do
		local minimum = GRADLE_MIN_FOR_JAVA[major]
		if (not minimum or at_least(gradle, minimum)) and (not best_major or major > best_major) then
			best, best_major = path, major
		end
	end

	return best
end

local mise_java_cache = {}
---@param root string
---@return string|nil
function M.project_java_home(root)
	if mise_java_cache[root] ~= nil then
		return mise_java_cache[root] or nil
	end

	local resolved = false
	if M.has_mise_config(root) then
		local home = mise(root, { "where", "java" })
		if home and vim.uv.fs_stat(home .. "/bin/java") then
			resolved = home
		end
	end
	resolved = resolved or M.gradle_compatible_java_home(root) or false

	mise_java_cache[root] = resolved
	return resolved or nil
end

local mise_gradle_cache = {}
---@param root string
---@return string|nil
function M.project_gradle_home(root)
	if mise_gradle_cache[root] ~= nil then
		return mise_gradle_cache[root] or nil
	end

	local function gradle_home(dir)
		if vim.uv.fs_stat(dir .. "/bin/gradle") then
			return dir
		end
		for name, type_ in vim.fs.dir(dir) do
			if (type_ == "directory" or type_ == "link") and vim.uv.fs_stat(dir .. "/" .. name .. "/bin/gradle") then
				return dir .. "/" .. name
			end
		end
		return nil
	end

	local resolved = false
	local dir = mise(root, { "where", "gradle" })
	if dir and vim.uv.fs_stat(dir) then
		resolved = gradle_home(dir) or false
	end

	mise_gradle_cache[root] = resolved
	return resolved or nil
end

return M
