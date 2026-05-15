return {
	{
		"williamboman/mason.nvim",
		dependencies = {
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
		},
		config = function()
			-- import mason
			local mason = require("mason")

			-- import mason-lspconfig
			local mason_lspconfig = require("mason-lspconfig")

			local mason_tool_installer = require("mason-tool-installer")

			-- enable mason and configure icons
			mason.setup({
				ui = {
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
			})

			mason_lspconfig.setup({
				-- list of servers for mason to install
				ensure_installed = {
					"ts_ls",
					"ansiblels",
					-- "html",
					-- "cssls",
					"tailwindcss",
					-- "svelte",
					-- "lua_ls",
					-- "graphql",
					-- "emmet_ls",
					-- "prismals",
					-- "r_language_server",
					-- "fsautocomplete",
					-- "csharp_ls",
					"pyright",
					"ruff",
					"gopls",
					"rust_analyzer",
					"jdtls",
				},
				-- auto-install configured servers (with lspconfig)
				automatic_installation = true, -- not the same as ensure_installed
			})

			mason_tool_installer.setup({
				ensure_installed = {
					"prettier", -- prettier formatter
					"stylua", -- lua formatter
					"ruff", -- python formatter/linter/LSP server
					-- "black", -- fallback formatter for Black-only Python repos
					"eslint_d", -- js linter
				},
			})
		end,
	},
	-- {
	--   "williamboman/mason-lspconfig.nvim",
	--   lazy = false,
	--   opts = {
	--     auto_install = true,
	--   },
	-- },
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		config = function()
			local diagnostics_enabled = true
			vim.g.lsp_semantic_tokens_enabled = false

			local function apply_semantic_tokens(bufnr, enabled)
				for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
					if client.server_capabilities.semanticTokensProvider then
						if enabled then
							pcall(vim.lsp.semantic_tokens.start, bufnr, client.id)
						else
							pcall(vim.lsp.semantic_tokens.stop, bufnr, client.id)
						end
					end
				end
			end

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("LspSemanticTokensToggle", { clear = true }),
				callback = function(args)
					apply_semantic_tokens(args.buf, vim.g.lsp_semantic_tokens_enabled)

					local client = args.data and vim.lsp.get_client_by_id(args.data.client_id) or nil
					if client and client.name == "ruff" then
						client.server_capabilities.hoverProvider = false
					end
				end,
			})

			if vim.fn.exists(":LspSemanticTokensToggle") == 2 then
				vim.api.nvim_del_user_command("LspSemanticTokensToggle")
			end

			vim.api.nvim_create_user_command("LspSemanticTokensToggle", function()
				vim.g.lsp_semantic_tokens_enabled = not vim.g.lsp_semantic_tokens_enabled
				local enabled = vim.g.lsp_semantic_tokens_enabled

				for _, buf in ipairs(vim.api.nvim_list_bufs()) do
					if vim.api.nvim_buf_is_loaded(buf) then
						apply_semantic_tokens(buf, enabled)
					end
				end

				vim.notify("LSP semantic tokens: " .. (enabled and "ON" or "OFF"), vim.log.levels.INFO)
			end, {})
			--			local function toggle_diagnostics()
			--				diagnostics_enabled = not diagnostics_enabled
			--				if diagnostics_enabled then
			--					vim.diagnostic.enable()
			--					vim.notify("Diagnostics enabled", vim.log.levels.INFO)
			--				else
			--					vim.diagnostic.disable()
			--					vim.notify("Diagnostics disabled", vim.log.levels.INFO)
			--				end
			--			end

			local function toggle_diagnostics()
				diagnostics_enabled = not diagnostics_enabled
				if diagnostics_enabled then
					vim.diagnostic.config({ virtual_text = true })
					vim.notify("Diagnostic virtual text enabled", vim.log.levels.INFO)
				else
					vim.diagnostic.config({ virtual_text = false })
					vim.notify("Diagnostic virtual text disabled", vim.log.levels.INFO)
				end
			end

			vim.diagnostic.config({
				underline = true,
				virtual_text = {
					right_align = true,
					padding = 0,
					prefix = "●", -- You can use '■', '▎', 'x', etc.
					spacing = 20,
					source = "if_many",
					severity = {
						min = vim.diagnostic.severity.HINT,
					},
				},

				float = false,
				signs = true,
				update_in_insert = false,
				severity_sort = true,
			})

			vim.keymap.set("n", "<A-d>d", toggle_diagnostics, { desc = "Toggle diagnostics" })
			vim.keymap.set("i", "<A-d>d", function()
				toggle_diagnostics()
				-- Return to insert mode since the toggle function might exit it
				vim.cmd("startinsert")
			end, { desc = "Toggle diagnostics" })

			vim.api.nvim_create_autocmd("ColorScheme", {
				callback = function()
					vim.cmd([[
      highlight DiagnosticVirtualTextError guibg=#3f0010 guifg=#ff8888
      highlight DiagnosticVirtualTextWarn guibg=#3f3000 guifg=#ffcc88
      highlight DiagnosticVirtualTextInfo guibg=#003f3f guifg=#88ccff
      highlight DiagnosticVirtualTextHint guibg=#2a2a3f guifg=#88aaff
    ]])
				end,
			})

			-- Apply the highlights immediately
			vim.cmd([[
  highlight DiagnosticVirtualTextError guibg=#3f0010 guifg=#ff8888
  highlight DiagnosticVirtualTextWarn guibg=#3f3000 guifg=#ffcc88
  highlight DiagnosticVirtualTextInfo guibg=#003f3f guifg=#88ccff
  highlight DiagnosticVirtualTextHint guibg=#2a2a3f guifg=#88aaff
]])
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			local cmp_nvim_lsp = require("cmp_nvim_lsp")

			vim.lsp.config.ts_ls = {
				capabilities = capabilities,
				-- require("lsp_signature").on_attach(signature_config, bufnr),
			}
			vim.lsp.enable("ts_ls")

			vim.lsp.config.html = {
				capabilities = capabilities,
			}
			vim.lsp.enable("html")

			vim.lsp.config.lua_ls = {
				capabilities = capabilities,
			}
			vim.lsp.enable("lua_ls")

			vim.lsp.config.ansiblels = {
				capabilities = capabilities,
			}
			vim.lsp.enable("ansiblels")

			vim.lsp.config.cucumber_language_server = {
				capabilities = capabilities,
				cmd = { "cucumber-language-server", "--stdio" },
				root_markers = { "package.json", ".git", "pyrightconfig.json", "README.md" },
				settings = {
					cucumber = {
						features = { "features/**/*.feature" },
						glue = {
							"features/**/*.py",
							"features/**/*.ts",
							"features/**/*.js",
						},
					},
				},
			}
			vim.lsp.enable("cucumber_language_server")

			vim.lsp.config.r_language_server = {
				capabilities = capabilities,
				-- 				require("lsp_signature").on_attach(signature_config, bufnr),
				cmd = {
					"R",
					"--slave",
					"-e",
					[[
      .libPaths(c(Sys.getenv("R_LIBS_USER"), .libPaths()))
			langserver <- languageserver:::LanguageServer$new("localhost", NULL);
			langserver$run()
		]],
				},
			}

			vim.lsp.config.terraformls = {
				capabilities = capabilities,
				on_attach = on_attach,
			}
			vim.lsp.enable("terraformls")

			vim.lsp.enable("r_language_server")

			vim.lsp.config.bashls = {
				capabilities = capabilities,
				on_attach = on_attach,
			}
			vim.lsp.enable("bashls")

			vim.lsp.config.pyright = {
				capabilities = capabilities,
				on_attach = on_attach,
			}
			vim.lsp.enable("pyright")

			vim.lsp.config.ruff = {
				capabilities = capabilities,
			}
			vim.lsp.enable("ruff")

			vim.lsp.config.svelte = {
				capabilities = capabilities,
				on_attach = on_attach,
			}
			vim.lsp.enable("svelte")

			vim.lsp.config.gopls = {
				capabilities = capabilities,
			}
			vim.lsp.enable("gopls")

			vim.lsp.config.rust_analyzer = {
				capabilities = capabilities,
				settings = {
					["rust-analyzer"] = {
						diagnostics = {
							enable = true,
						},
					},
				},
			}
			vim.lsp.enable("rust_analyzer")

			vim.lsp.config.jdtls = {
				capabilities = capabilities,
			}
			vim.lsp.enable("jdtls")

			vim.lsp.config.tailwindcss = {
				capabilities = capabilities,
				on_attach = on_attach,
				filetypes = { "html", "css", "javascript", "jsx", "typescript", "tsx", "svelte", "python" },
				settings = {
					tailwindCSS = {
						includeLanguages = {
							python = "html",
						},
						experimental = {
							configFile = "styles.css",
							classRegex = {
								{ "class_\\s*=\\s*['\"]([^'\"]*)['\"]" },
								{ "_class\\s*=\\s*['\"]([^'\"]*)['\"]" },
							},
						},
					},
				},
			}
			vim.lsp.enable("tailwindcss")

			--.libPaths(new = "~/.local/share/nvim/lsp_servers/r_language_server");

			-- keymap.set(
			-- 	"n",
			-- 	"<leader>ff",
			-- 	"<cmd>Telescope lsp_implementations<cr>",
			-- 	{ desc = "Fuzzy find files in cwd" }
			-- )
			-- keymap.set(
			-- 	"n",
			-- 	"<leader>ff",
			-- 	"<cmd>Telescope lsp_document_symbols<cr>",
			-- 	{ desc = "Fuzzy find files in cwd" }
			-- )
			-- keymap.set(
			-- 	"n",
			-- 	"<leader>ff",
			-- 	"<cmd>Telescope lsp_workspaces_symbols<cr>",
			-- 	{ desc = "Fuzzy find files in cwd" }
			-- )
			vim.keymap.set("n", "<leader>q", vim.lsp.buf.hover, {})
			vim.keymap.set("n", "<A>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
			-- FIX: Workspace diagnostics currently behave differently on macOS than on Linux.
			vim.keymap.set("n", "<leader>E", "<cmd>Telescope diagnostics<CR>", { desc = "List diagnostics" })
			vim.keymap.set("n", "<leader>e", "<cmd>Telescope diagnostics bufnr=0<CR>", { desc = "Buffer diagnostics" })
			-- as well as easily fix it with exception if needed
			-- code actions in telescope
			-- vim.diagnostic.goto_next()
			vim.keymap.set("n", "<leader>w", vim.lsp.buf.signature_help, {})
			vim.keymap.set("n", "<leader>d", vim.lsp.buf.definition, {})
			vim.keymap.set("n", "<leader>j", vim.lsp.buf.type_definition, {})
			vim.keymap.set("n", "<leader>g", vim.diagnostic.setqflist, {})
			vim.keymap.set("n", "<leader>r", "<cmd>Telescope lsp_references<cr>", {})
			vim.keymap.set("n", "<leader>i", "<cmd>Telescope lsp_implementations<cr>", {})
			vim.keymap.set("n", "<leader>f", "<cmd>Telescope lsp_document_symbols<cr>", {})
			vim.keymap.set("n", "<leader>p", "<cmd>Telescope lsp_workspace_symbols<cr>", {})
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
			vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, {})
			vim.keymap.set("n", "<leader>ut", "<cmd>LspSemanticTokensToggle<CR>", { desc = "Toggle LSP semantic tokens" })
			-- vim.keymap.set("n", "<leader>r", vim.lsp.buf.references, {})
		end,
	},
}
