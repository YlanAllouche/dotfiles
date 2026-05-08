local parsers_to_install = {
	"json",
	"javascript",
	"typescript",
	"tsx",
	"yaml",
	"html",
	"css",
	"markdown",
	"markdown_inline",
	"bash",
	"lua",
	"vim",
	"dockerfile",
	"gitignore",
	"gherkin",
	"query",
	"c",
	"cpp",
	"rust",
	"python",
	"go",
	"r",
	"vimdoc",
	"c_sharp",
	"jsdoc",
}

local function setup_treesitter_compat()
	local parsers = require("nvim-treesitter.parsers")
	parsers.ft_to_lang = parsers.ft_to_lang or vim.treesitter.language.get_lang
	parsers.get_parser = parsers.get_parser or vim.treesitter.get_parser

	package.preload["nvim-treesitter.configs"] = function()
		return {
			is_enabled = function(module, lang, bufnr)
				if module ~= "highlight" then
					return false
				end

				if not lang or not bufnr then
					return false
				end

				local ok_parser = pcall(vim.treesitter.get_parser, bufnr, lang)
				if not ok_parser then
					return false
				end

				local get_query = vim.treesitter.query.get or vim.treesitter.get_query
				return pcall(get_query, lang, "highlights")
			end,
			get_module = function(module)
				if module == "highlight" then
					return {
						additional_vim_regex_highlighting = false,
					}
				end

				return {}
			end,
		}
	end
end

local function register_gherkin_parser()
	local parsers = require("nvim-treesitter.parsers")
	if parsers.gherkin then
		return
	end

	parsers.gherkin = {
		install_info = {
			url = "https://github.com/binhtddev/tree-sitter-gherkin",
			files = { "src/parser.c", "src/scanner.c" },
			branch = "main",
			queries = "queries",
		},
	}
end

local function enable_treesitter_features()
	local function enable_for_buffer(bufnr)
		if vim.bo[bufnr].buftype ~= "" then
			return
		end

		local ok = pcall(vim.treesitter.start, bufnr)
		if not ok then
			return
		end

		vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

		local win = vim.fn.bufwinid(bufnr)
		if win ~= -1 then
			vim.wo[win].foldexpr = "v:lua.vim.treesitter.foldexpr()"
			vim.wo[win].foldmethod = "expr"
		end
	end

	local group = vim.api.nvim_create_augroup("treesitter-features", { clear = true })
	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		callback = function(args)
			enable_for_buffer(args.buf)
		end,
	})

	vim.schedule(function()
		enable_for_buffer(vim.api.nvim_get_current_buf())
	end)
end

local function install_missing_parsers()
	if #vim.api.nvim_list_uis() == 0 then
		return
	end

	local treesitter = require("nvim-treesitter")
	local installed = {}
	for _, parser in ipairs(treesitter.get_installed()) do
		installed[parser] = true
	end

	local missing = {}
	for _, parser in ipairs(parsers_to_install) do
		if not installed[parser] then
			table.insert(missing, parser)
		end
	end

	if #missing > 0 then
		treesitter.install(missing)
	end
end

local function setup_incremental_selection()
	local select = require("vim.treesitter._select")

	local function select_current_or_parent()
		if vim.api.nvim_get_mode().mode == "n" then
			vim.cmd.normal({ "v", bang = true })
		end
		select.select_parent(vim.v.count1)
	end

	for _, lhs in ipairs({ "<C-space>", "<C-@>" }) do
		vim.keymap.set({ "n", "x" }, lhs, select_current_or_parent, {
			desc = "Treesitter incremental select",
		})
	end
	vim.keymap.set({ "n", "x" }, "-", function()
		select.select_child(vim.v.count1)
	end, {
		desc = "Treesitter incremental shrink",
	})
	vim.keymap.set({ "n", "x" }, "<M-space>", function()
		select.select_child(vim.v.count1)
	end, {
		desc = "Treesitter incremental shrink",
	})
end

local function setup_textobjects()
	require("nvim-treesitter-textobjects").setup({
		select = {
			lookahead = true,
		},
		move = {
			set_jumps = true,
		},
	})

	local select = require("nvim-treesitter-textobjects.select")
	local move = require("nvim-treesitter-textobjects.move")
	local swap = require("nvim-treesitter-textobjects.swap")

	local select_keymaps = {
		["a="] = { query = "@assignment.outer", desc = "Select outer part of an assignment" },
		["i="] = { query = "@assignment.inner", desc = "Select inner part of an assignment" },
		["l="] = { query = "@assignment.lhs", desc = "Select left hand side of an assignment" },
		["r="] = { query = "@assignment.rhs", desc = "Select right hand side of an assignment" },
		["a:"] = { query = "@property.outer", desc = "Select outer part of an object property" },
		["i:"] = { query = "@property.inner", desc = "Select inner part of an object property" },
		["l:"] = { query = "@property.lhs", desc = "Select left part of an object property" },
		["r:"] = { query = "@property.rhs", desc = "Select right part of an object property" },
		["aa"] = { query = "@parameter.outer", desc = "Select outer part of a parameter/argument" },
		["ia"] = { query = "@parameter.inner", desc = "Select inner part of a parameter/argument" },
		["ai"] = { query = "@conditional.outer", desc = "Select outer part of a conditional" },
		["ii"] = { query = "@conditional.inner", desc = "Select inner part of a conditional" },
		["al"] = { query = "@loop.outer", desc = "Select outer part of a loop" },
		["il"] = { query = "@loop.inner", desc = "Select inner part of a loop" },
		["af"] = { query = "@call.outer", desc = "Select outer part of a function call" },
		["if"] = { query = "@call.inner", desc = "Select inner part of a function call" },
		["am"] = { query = "@function.outer", desc = "Select outer part of a method/function definition" },
		["im"] = { query = "@function.inner", desc = "Select inner part of a method/function definition" },
		["ac"] = { query = "@class.outer", desc = "Select outer part of a class" },
		["ic"] = { query = "@class.inner", desc = "Select inner part of a class" },
	}

	for lhs, spec in pairs(select_keymaps) do
		vim.keymap.set({ "x", "o" }, lhs, function()
			select.select_textobject(spec.query, spec.query_group)
		end, { desc = spec.desc })
	end

	local swap_keymaps = {
		{ lhs = "<leader>na", action = swap.swap_next, query = "@parameter.inner", desc = "Swap with next parameter" },
		{ lhs = "<leader>n:", action = swap.swap_next, query = "@property.outer", desc = "Swap with next property" },
		{ lhs = "<leader>nm", action = swap.swap_next, query = "@function.outer", desc = "Swap with next function" },
		{ lhs = "<leader>pa", action = swap.swap_previous, query = "@parameter.inner", desc = "Swap with previous parameter" },
		{ lhs = "<leader>p:", action = swap.swap_previous, query = "@property.outer", desc = "Swap with previous property" },
		{ lhs = "<leader>pm", action = swap.swap_previous, query = "@function.outer", desc = "Swap with previous function" },
	}

	for _, spec in ipairs(swap_keymaps) do
		vim.keymap.set("n", spec.lhs, function()
			spec.action(spec.query, spec.query_group)
		end, { desc = spec.desc })
	end

	local move_keymaps = {
		{ lhs = "]f", action = move.goto_next_start, query = "@call.outer", desc = "Next function call start" },
		{ lhs = "]m", action = move.goto_next_start, query = "@function.outer", desc = "Next method/function def start" },
		{ lhs = "]c", action = move.goto_next_start, query = "@class.outer", desc = "Next class start" },
		{ lhs = "]i", action = move.goto_next_start, query = "@conditional.outer", desc = "Next conditional start" },
		{ lhs = "]l", action = move.goto_next_start, query = "@loop.outer", desc = "Next loop start" },
		{ lhs = "]s", action = move.goto_next_start, query = "@scope", query_group = "locals", desc = "Next scope" },
		{ lhs = "]z", action = move.goto_next_start, query = "@fold", query_group = "folds", desc = "Next fold" },
		{ lhs = "]F", action = move.goto_next_end, query = "@call.outer", desc = "Next function call end" },
		{ lhs = "]M", action = move.goto_next_end, query = "@function.outer", desc = "Next method/function def end" },
		{ lhs = "]C", action = move.goto_next_end, query = "@class.outer", desc = "Next class end" },
		{ lhs = "]I", action = move.goto_next_end, query = "@conditional.outer", desc = "Next conditional end" },
		{ lhs = "]L", action = move.goto_next_end, query = "@loop.outer", desc = "Next loop end" },
		{ lhs = "[f", action = move.goto_previous_start, query = "@call.outer", desc = "Prev function call start" },
		{ lhs = "[m", action = move.goto_previous_start, query = "@function.outer", desc = "Prev method/function def start" },
		{ lhs = "[c", action = move.goto_previous_start, query = "@class.outer", desc = "Prev class start" },
		{ lhs = "[i", action = move.goto_previous_start, query = "@conditional.outer", desc = "Prev conditional start" },
		{ lhs = "[l", action = move.goto_previous_start, query = "@loop.outer", desc = "Prev loop start" },
		{ lhs = "[F", action = move.goto_previous_end, query = "@call.outer", desc = "Prev function call end" },
		{ lhs = "[M", action = move.goto_previous_end, query = "@function.outer", desc = "Prev method/function def end" },
		{ lhs = "[C", action = move.goto_previous_end, query = "@class.outer", desc = "Prev class end" },
		{ lhs = "[I", action = move.goto_previous_end, query = "@conditional.outer", desc = "Prev conditional end" },
		{ lhs = "[L", action = move.goto_previous_end, query = "@loop.outer", desc = "Prev loop end" },
	}

	for _, spec in ipairs(move_keymaps) do
		vim.keymap.set({ "n", "x", "o" }, spec.lhs, function()
			spec.action(spec.query, spec.query_group)
		end, { desc = spec.desc })
	end

	local ts_repeat_move = require("nvim-treesitter-textobjects.repeatable_move")
	vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move)
	vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_opposite)
	vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f_expr, { expr = true })
	vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F_expr, { expr = true })
	vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t_expr, { expr = true })
	vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T_expr, { expr = true })
end

return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		dependencies = {
			"windwp/nvim-ts-autotag",
		},
		init = function()
			vim.api.nvim_create_autocmd("User", {
				pattern = "TSUpdate",
				callback = function()
					register_gherkin_parser()
				end,
			})
		end,
		config = function()
			setup_treesitter_compat()
			register_gherkin_parser()
			vim.treesitter.language.register("gherkin", { "cucumber", "gherkin" })
			enable_treesitter_features()
			setup_incremental_selection()
			vim.schedule(install_missing_parsers)
			require("nvim-ts-autotag").setup({
				opts = {
					enable_close = true,
					enable_rename = true,
					enable_close_on_slash = false,
				},
				per_filetype = {},
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		lazy = false,
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			setup_textobjects()
		end,
	},
}
