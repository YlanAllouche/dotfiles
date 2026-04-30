return {
	"kevinhwang91/rnvimr",
	config = function()
		vim.keymap.set("n", "<C-n>", ":RnvimrToggle<CR>", { noremap = true, silent = true })
		vim.keymap.set("t", "<C-n>", ":RnvimrToggle<CR>", { noremap = true, silent = true })
		vim.g.rnvimr_enable_ex = 1
		vim.g.rnvimr_enable_picker = 1
		vim.g.rnvimr_edit_cmd = "drop"
		vim.g.rnvimr_action = {
			["<C-e>"] = "NvimEdit tabedit",
			["<C-x>"] = "NvimEdit split",
			["<C-v>"] = "NvimEdit vsplit",
			["gw"] = "JumpNvimCwd",
			["yw"] = "EmitRangerCwd",
		}
	end,
}
