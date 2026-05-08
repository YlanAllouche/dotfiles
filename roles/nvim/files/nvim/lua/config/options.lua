-- opt.wrap = true -- disable line wrapping
vim.opt.autoindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes:1" -- Exactly 1 column for signs (minimized width)
vim.opt.clipboard:append("unnamedplus")
vim.opt.backspace = "indent,eol,start"
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.o.completeopt = "menuone,noselect"
vim.o.hlsearch = false
vim.o.mouse = "a"
vim.o.undofile = true
vim.opt.swapfile = false
vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.opt.shortmess:append({ I = true })
-- vim.cmd("hi Normal guibg=NONE")
vim.keymap.set("n", "<A-h>", ":nohlsearch<CR>")
vim.wo.number = true
vim.cmd.colorscheme("vim")
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.fillchars = { eob = " " }
vim.cmd.colorscheme("lushwal")
vim.opt.foldmethod = "manual"
vim.opt.foldlevel = 99 -- Adjust to your preference
vim.opt.foldlevelstart = 99 -- Adjust to your preference
vim.opt.foldenable = true
vim.opt.foldcolumn = "0" -- Reduce extra gutter space from fold column
vim.o.autoread = true
-- vim.o.breakindent = true
-- vim.api.nvim_set_hl(0, 'Normal', { bg = 'NONE', ctermbg = 'NONE' })
-- vim.o.updatetime = 250
-- vim.o.timeoutlen = 300
-- vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
-- 	pattern = "*",
-- 	command = "checktime",
-- })
--
local italic_groups = {
	"Comment",
	"Keyword",
	"Type",
	"Boolean",
	"Constant",
	"Conditional",
	"Repeat",
	"Exception",
	"Function",
}

for _, group in ipairs(italic_groups) do
	vim.api.nvim_set_hl(10000, group, { italic = true })
end
