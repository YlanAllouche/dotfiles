-- Starts (or attaches to) eclipse.jdt.ls for this buffer.
--
-- This file is the single entry point for Java LSP: `lua/plugins/lsp.lua` must
-- not enable `jdtls`, otherwise two jdtls clients attach to the same buffer and
-- fight over the workspace lock.

local ok, jdtls = pcall(require, "jdtls")
if not ok then
	return
end

local env = require("jdtls_env")

local launcher = env.launcher_jar()
if not launcher then
	vim.notify("jdtls is not installed - run :MasonInstall jdtls", vim.log.levels.WARN)
	return
end

local java_home = env.jdtls_java_home()
if not java_home then
	vim.notify("No JDK 21+ found to run jdtls - install the Java toolchains through mise", vim.log.levels.WARN)
	return
end

local root = env.project_root(0)
if not root then
	return
end

-- One workspace per checkout, grouped by repository. Git worktrees each get
-- their own: an Eclipse workspace stores absolute paths and a single flat
-- namespace of project names, so two worktrees of the same repo sharing one
-- would resolve each other's sources.
local workspace = env.workspace(root)

local has_wrapper = vim.uv.fs_stat(root .. "/gradlew") ~= nil
local gradle_home = (not has_wrapper) and env.project_gradle_home(root) or nil
local gradle_java_home = env.project_java_home(root)

-- Remote-attach debug configuration, always available. `port` is a function so
-- nvim-dap asks only when a session actually starts, not on every buffer.
-- 8000 is what `catalina.sh jpda run` uses; 5005 is the usual plain-JVM default.
local attach_config = {
	type = "java",
	request = "attach",
	name = "Attach to remote JVM (JDWP)",
	hostName = "127.0.0.1",
	port = function()
		return tonumber(vim.fn.input("JDWP port: ", "8000")) or 8000
	end,
}

local cmd = {
	java_home .. "/bin/java",
	"-Declipse.application=org.eclipse.jdt.ls.core.id1",
	"-Dosgi.bundles.defaultStartLevel=4",
	"-Declipse.product=org.eclipse.jdt.ls.core.product",
	"-Dlog.protocol=true",
	"-Dlog.level=ALL",
	"-Dfile.encoding=UTF-8",
	-- Keep Eclipse metadata out of the checkout itself.
	"-Djava.import.generatesMetadataFilesAtProjectRoot=false",
	"-Xmx4g",
	"--add-modules=ALL-SYSTEM",
	"--add-opens",
	"java.base/java.util=ALL-UNNAMED",
	"--add-opens",
	"java.base/java.lang=ALL-UNNAMED",
}

-- Lombok rewrites the AST at compile time; without the agent every generated
-- getter/setter/builder shows up as an unresolved symbol.
if vim.uv.fs_stat(env.lombok_jar) then
	table.insert(cmd, "-javaagent:" .. env.lombok_jar)
end

vim.list_extend(cmd, {
	"-jar",
	launcher,
	"-configuration",
	env.config_dir(workspace),
	"-data",
	workspace,
})

local settings = {
	java = {
		configuration = {
			updateBuildConfiguration = "interactive",
			runtimes = env.runtimes(),
		},
		import = {
			gradle = {
				enabled = true,
				-- Some repositories ship no `gradlew` and rely on the mise-managed
				-- Gradle pinned in their repo config. When a wrapper exists, let jdtls
				-- use it instead.
				wrapper = { enabled = has_wrapper },
				home = gradle_home,
				java = { home = gradle_java_home },
				offline = { enabled = false },
			},
			maven = { enabled = true },
		},
		eclipse = { downloadSources = true },
		maven = { downloadSources = true },
		implementationsCodeLens = { enabled = false },
		referencesCodeLens = { enabled = false },
		signatureHelp = { enabled = true, description = { enabled = true } },
		contentProvider = { preferred = "fernflower" },
		sources = {
			organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 },
		},
		completion = {
			favoriteStaticMembers = {
				"org.junit.jupiter.api.Assertions.*",
				"org.junit.jupiter.api.Assumptions.*",
				"org.junit.Assert.*",
				"org.junit.Assume.*",
				"org.mockito.Mockito.*",
				"org.mockito.ArgumentMatchers.*",
				"org.assertj.core.api.Assertions.*",
				"java.util.Objects.requireNonNull",
				"java.util.Objects.requireNonNullElse",
			},
			filteredTypes = {
				"com.sun.*",
				"io.micrometer.shaded.*",
				"java.awt.*",
				"jdk.*",
				"sun.*",
			},
			importOrder = { "java", "javax", "com", "org" },
		},
		codeGeneration = {
			toString = {
				template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
			},
			hashCodeEquals = { useJava7Objects = true },
			useBlocks = true,
		},
		format = { enabled = true },
	},
}

local config = {
	name = "jdtls",
	cmd = cmd,
	root_dir = root,
	capabilities = require("cmp_nvim_lsp").default_capabilities(),
	init_options = {
		bundles = env.bundles(),
		extendedClientCapabilities = vim.tbl_deep_extend("force", jdtls.extendedClientCapabilities, {
			resolveAdditionalTextEditsSupport = true,
		}),
		-- jdtls reads the Gradle import preferences during `initialize`, before
		-- `workspace/didChangeConfiguration` ever arrives.
		settings = settings,
	},
	settings = settings,
	on_attach = function(client, bufnr)
		-- A checkout imported before its bootstrap build ran keeps a classpath that
		-- is missing the built jars, and Buildship never re-syncs on its own.
		if env.classpath_outdated(root) and not env.resynced[root] then
			env.resynced[root] = true
			client:notify("java/projectConfigurationUpdate", {
				uri = env.project_build_uri(root),
			})
			vim.notify(
				("%s was built after it was indexed - re-importing."):format(vim.fn.fnamemodify(root, ":~")),
				vim.log.levels.INFO,
				{ title = "Java" }
			)
		end

		local function map(lhs, rhs, desc)
			vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
		end

		map("<leader>Jo", jdtls.organize_imports, "Java: organize imports")
		map("<leader>Jv", jdtls.extract_variable, "Java: extract variable")
		map("<leader>Jc", jdtls.extract_constant, "Java: extract constant")
		map("<leader>Jm", jdtls.extract_method, "Java: extract method")
		map("<leader>Ju", "<cmd>JdtUpdateConfig<cr>", "Java: update project config")
		map("<leader>Jt", jdtls.test_nearest_method, "Java: test nearest method")
		map("<leader>JT", jdtls.test_class, "Java: test class")

		vim.keymap.set("v", "<leader>Jv", function()
			jdtls.extract_variable({ visual = true })
		end, { buffer = bufnr, desc = "Java: extract variable" })
		vim.keymap.set("v", "<leader>Jc", function()
			jdtls.extract_constant({ visual = true })
		end, { buffer = bufnr, desc = "Java: extract constant" })
		vim.keymap.set("v", "<leader>Jm", function()
			jdtls.extract_method({ visual = true })
		end, { buffer = bufnr, desc = "Java: extract method" })

		pcall(jdtls.setup_dap, { hotcodereplace = "auto", config_overrides = {} })
		pcall(function()
			require("jdtls.dap").setup_dap_main_class_configs({ verbose = false })
		end)

		pcall(function()
			local dap = require("dap")
			dap.configurations.java = dap.configurations.java or {}
			for _, existing in ipairs(dap.configurations.java) do
				if existing.name == attach_config.name then
					return
				end
			end
			table.insert(dap.configurations.java, attach_config)
		end)
	end,
}

jdtls.start_or_attach(config)

-- A checkout whose build has never run resolves nothing, and jdtls reports that
-- as ordinary "cannot be resolved" errors with no hint about the cause.
local function warn_if_not_bootstrapped()
	if env.warned[root] then
		return
	end

	local pending, bootstrap, dirs = env.bootstrap_pending(root)
	if not pending then
		return
	end
	env.warned[root] = true

	if bootstrap and bootstrap.cmd and bootstrap.auto then
		return require("jdtls_bootstrap").run(root, bootstrap, { visible = false })
	end

	vim.notify(
		("%s has not been built yet, so part of its classpath does not exist:\n  %s\n\n%s"):format(
			vim.fn.fnamemodify(root, ":~"),
			table.concat(dirs, "\n  "),
			bootstrap and bootstrap.cmd and (":JavaBootstrap will " .. bootstrap.description)
				or ":JavaBootstrap will show what is missing"
		),
		vim.log.levels.WARN,
		{ title = "Java" }
	)
end

warn_if_not_bootstrapped()
if not env.warned[root] then
	vim.defer_fn(warn_if_not_bootstrapped, 90000)
end
