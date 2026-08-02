return {
	{
		"mfussenegger/nvim-jdtls",
		ft = { "java" },
		dependencies = { "mfussenegger/nvim-dap" },
		init = function()
			vim.api.nvim_create_user_command("JavaHealth", function()
				local env = require("jdtls_env")
				local lines = {}

				local function add(label, value)
					table.insert(lines, ("%-22s %s"):format(label, value))
				end

				local launcher = env.launcher_jar()
				add("jdtls launcher", launcher and vim.fs.basename(launcher) or "MISSING (:MasonInstall jdtls)")
				add("lombok agent", vim.uv.fs_stat(env.lombok_jar) and "ok" or "MISSING")
				add("jdtls runtime", env.jdtls_java_home() or "MISSING (needs JDK 21+)")

				local bundles = env.bundles()
				add(
					"debug/test bundles",
					#bundles > 0 and (#bundles .. " jars") or "MISSING (run scripts/install-java-bundles.sh)"
				)

				for _, rt in ipairs(env.runtimes()) do
					add(rt.name, rt.path .. (rt.default and "  (default)" or ""))
				end

				local root = env.project_root(0)
				add("project root", root or "not a JVM project")
				if root then
					add("repository", env.repo_name(root))
					add("workspace", vim.fn.fnamemodify(env.workspace(root), ":~"))
					local has_wrapper = vim.uv.fs_stat(root .. "/gradlew") ~= nil
					add("gradle wrapper", has_wrapper and "yes" or "no")
					add("gradle home", has_wrapper and "(wrapper)" or (env.project_gradle_home(root) or "-"))
					add("project JDK", env.project_java_home(root) or "-")

					local progress = require("jdtls_bootstrap").status(root)
					if progress then
						add("bootstrap", progress)
					end

					local pending, bootstrap, dirs = env.bootstrap_pending(root)
					if pending then
						add("classpath gaps", ("missing files under %s"):format(table.concat(dirs, ", ")))
						add("  fix", bootstrap and ":JavaBootstrap" or ":JavaBootstrap (reports what is missing)")
					elseif pending == nil then
						add("classpath gaps", "unknown - no resolved classpath, import unfinished or failed")
					else
						add("classpath gaps", "none")
					end
				end

				local client = vim.lsp.get_clients({ bufnr = 0, name = "jdtls" })[1]
				add("attached client", client and ("id " .. client.id) or "none")

				if client then
					local cp = client:request_sync("workspace/executeCommand", {
						command = "java.project.getClasspaths",
						arguments = { vim.uri_from_bufnr(0), vim.json.encode({ scope = "runtime" }) },
					}, 10000, 0)
					local entries = cp and cp.result and cp.result.classpaths
					add("classpath", entries and #entries > 0 and (#entries .. " entries") or "not reported")

					local unresolved = 0
					for _, d in ipairs(vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })) do
						if d.message:match("cannot be resolved") then
							unresolved = unresolved + 1
						end
					end
					if unresolved > 0 then
						add("unresolved types", unresolved .. " - the build import is incomplete")
						local pending = select(1, env.bootstrap_pending(root or ""))
						if pending then
							add("  fix", ":JavaBootstrap  (this checkout has never been built)")
						else
							add("  fix 1", "`gradle projects` must succeed for this checkout")
							add("  fix 2", ":JdtUpdateConfig, or :JavaWorkspaces to wipe and re-import")
						end
					else
						add("unresolved types", "none")
					end
				end

				local buf = vim.api.nvim_create_buf(false, true)
				vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
				vim.bo[buf].modifiable = false
				vim.bo[buf].filetype = "javahealth"

				local width = 0
				for _, line in ipairs(lines) do
					width = math.max(width, #line)
				end

				local height = math.min(#lines, vim.o.lines - 6)
				local popup_width = math.min(width + 2, vim.o.columns - 4)
				local win = vim.api.nvim_open_win(buf, true, {
					relative = "editor",
					width = popup_width,
					height = height,
					row = math.floor((vim.o.lines - height) / 2) - 1,
					col = math.floor((vim.o.columns - popup_width) / 2),
					style = "minimal",
					border = "rounded",
					title = " Java health ",
					title_pos = "center",
				})
				vim.wo[win].wrap = false

				for _, key in ipairs({ "q", "<Esc>" }) do
					vim.keymap.set("n", key, function()
						if vim.api.nvim_win_is_valid(win) then
							vim.api.nvim_win_close(win, true)
						end
					end, { buffer = buf, nowait = true })
				end
			end, { desc = "Report the state of the Java toolchain" })

			vim.api.nvim_create_user_command("JavaBootstrap", function(opts)
				local env = require("jdtls_env")
				local root = env.project_root(0)
				if not root then
					return vim.notify("Not inside a JVM project", vim.log.levels.ERROR, { title = "Java" })
				end

				local pending, bootstrap, dirs = env.bootstrap_pending(root)
				if pending == false and not opts.bang then
					return vim.notify(
						("%s looks fully built - every jar on its classpath exists.\nUse :JavaBootstrap! to run it anyway."):format(
							env.repo_name(root)
						),
						vim.log.levels.INFO,
						{ title = "Java" }
					)
				end

				if not (bootstrap and bootstrap.cmd) then
					if pending == nil then
						return vim.notify(
							("No resolved classpath for %s yet, so nothing can be checked.\nEither the Gradle/Maven import has not finished, or it failed -\n:JavaHealth and the jdtls log will say which."):format(
								env.repo_name(root)
							),
							vim.log.levels.WARN,
							{ title = "Java" }
						)
					end

					return vim.notify(
						('%d jar(s) on the classpath do not exist yet:\n  %s\n\nSomething in this build has to produce them. Once you know what,\nrecord it in ~/.local/java-projects.lua so every worktree on this\nmachine can reuse it.'):format(
							#(env.classpath_gaps(root) or {}),
							table.concat(dirs, "\n  ")
						),
						vim.log.levels.WARN,
						{ title = "Java" }
					)
				end

				require("jdtls_bootstrap").run(root, bootstrap, { visible = true })
				vim.cmd("startinsert")
			end, { bang = true, desc = "Run the build step this checkout needs before indexing" })

			vim.api.nvim_create_user_command("JavaWorkspaces", function()
				local env = require("jdtls_env")
				local all = env.workspaces()
				if #all == 0 then
					return vim.notify("No jdtls workspaces yet", vim.log.levels.INFO, { title = "Java" })
				end

				local current = env.project_root(0)
				local items = {}
				for _, ws in ipairs(all) do
					local flag = ws.stale and " [worktree gone]" or (ws.root == current and " [current]" or "")
					table.insert(items, {
						ws = ws,
						label = ("%-18s %s%s"):format(ws.repo, vim.fn.fnamemodify(ws.root or ws.dir, ":~"), flag),
					})
				end

				vim.ui.select(items, {
					prompt = "jdtls workspaces (select to delete and force a re-import)",
					format_item = function(item)
						return item.label
					end,
				}, function(choice)
					if not choice then
						return
					end
					vim.fn.delete(choice.ws.dir, "rf")
					vim.notify(
						("Deleted %s.\n%s"):format(
							vim.fn.fnamemodify(choice.ws.dir, ":~"),
							choice.ws.root == current and "Restart nvim to re-import this checkout."
								or "It will be re-imported next time a Java file is opened there."
						),
						vim.log.levels.INFO,
						{ title = "Java" }
					)
				end)
			end, { desc = "List jdtls workspaces; select one to delete it" })
		end,
	},
}
