-- journal_navigation.lua

-- Configuration
local journal_path = vim.fn.expand("~/share/notes/journal")

-- Helper function to format date as YYYY-MM-DD
local function format_date(date)
	return os.date("%Y-%m-%d", date)
end

-- Helper function to get timestamp for a date offset from today
local function get_date_timestamp(day_offset)
	local day_seconds = 86400 -- seconds in a day
	local current_time = os.time()
	return current_time + (day_seconds * day_offset)
end

-- Helper function to navigate to a journal note for a specific date
local function go_to_journal(day_offset)
	local date_timestamp = get_date_timestamp(day_offset)
	local date_string = format_date(date_timestamp)
	local file_path = journal_path .. "/" .. date_string .. ".md"

	-- Check if file exists
	if vim.fn.filereadable(file_path) == 1 then
		vim.cmd("edit " .. file_path)
	else
		vim.notify("Journal file for " .. date_string .. " doesn't exist", vim.log.levels.WARN)
	end
end

-- Function to go to today's journal
local function go_to_today_journal()
	go_to_journal(0)
end

-- Function to go to yesterday's journal
local function go_to_yesterday_journal()
	go_to_journal(-1)
end

-- Function to go to tomorrow's journal
local function go_to_tomorrow_journal()
	go_to_journal(1)
end

-- Setup keymaps
local function setup_journal_keymaps()
	-- Global keymaps for journal navigation
	vim.keymap.set("n", "<leader>jt", go_to_today_journal, { desc = "Go to Today's Journal" })
	vim.keymap.set("n", "<leader>jy", go_to_yesterday_journal, { desc = "Go to Yesterday's Journal" })
	vim.keymap.set("n", "<leader>jn", go_to_tomorrow_journal, { desc = "Go to Tomorrow's Journal" })
end

-- Initialize the keymaps
setup_journal_keymaps()

-- Return the module (optional, for requiring in other files)
return {
	go_to_today_journal = go_to_today_journal,
	go_to_yesterday_journal = go_to_yesterday_journal,
	go_to_tomorrow_journal = go_to_tomorrow_journal,
}
