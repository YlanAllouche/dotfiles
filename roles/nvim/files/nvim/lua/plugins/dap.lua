return {
	{
		"mfussenegger/nvim-dap",
		config = function()
			local dap = require("dap")

			vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticSignError" })
			vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "DiagnosticSignWarn" })
			vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "DiagnosticSignError" })
			vim.fn.sign_define("DapLogPoint", { text = "", texthl = "DiagnosticSignInfo" })
			vim.fn.sign_define(
				"DapStopped",
				{ text = "", texthl = "DiagnosticSignInfo", linehl = "Visual", numhl = "DiagnosticSignInfo" }
			)

			vim.keymap.set("n", "<A-d>b", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
			vim.keymap.set("n", "<A-d>c", dap.continue, { desc = "Start or continue debugging" })
			vim.keymap.set("n", "<A-d>i", dap.step_into, { desc = "Step into" })
			vim.keymap.set("n", "<A-d>o", dap.step_over, { desc = "Step over" })
			vim.keymap.set("n", "<A-d>O", dap.step_out, { desc = "Step out" })
			vim.keymap.set("n", "<A-d>r", dap.repl.open, { desc = "Open debug REPL" })
			vim.keymap.set("n", "<A-d>u", function()
				require("dapui").toggle({})
			end, { desc = "Toggle debug UI" })
			vim.keymap.set("n", "<A-d>x", dap.terminate, { desc = "Terminate debug session" })
			vim.keymap.set("n", "<A-d>s", function()
				require("telescope").extensions.dap.commands({})
			end, { desc = "Search DAP commands" })
		end,
	},
	{
		"mfussenegger/nvim-dap-python",
		ft = { "python" },
		dependencies = {
			"mfussenegger/nvim-dap",
		},
		config = function()
			local dap_python = require("dap-python")
			local python3 = vim.fn.exepath("python3")

			dap_python.setup(python3 ~= "" and python3 or "python3")

			vim.keymap.set("n", "<A-d>t", dap_python.test_method, { desc = "Debug nearest Python test" })
			vim.keymap.set("n", "<A-d>T", dap_python.test_class, { desc = "Debug Python test class" })
		end,
	},
	{
		"rcarriga/nvim-dap-ui",
		dependencies = {
			"mfussenegger/nvim-dap",
			"nvim-neotest/nvim-nio",
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			dapui.setup({})

			dap.listeners.before.attach.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.launch.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated.dapui_config = function()
				dapui.close()
			end
			dap.listeners.before.event_exited.dapui_config = function()
				dapui.close()
			end
		end,
	},
	{
		"theHamsta/nvim-dap-virtual-text",
		dependencies = {
			"mfussenegger/nvim-dap",
			"nvim-treesitter/nvim-treesitter",
		},
		opts = {},
	},
	{
		"nvim-telescope/telescope-dap.nvim",
		dependencies = {
			"nvim-telescope/telescope.nvim",
			"mfussenegger/nvim-dap",
		},
		config = function()
			require("telescope").load_extension("dap")
		end,
	},
}
