local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node
local f = ls.function_node

return {
	-- ============ SVELTE COMPONENT BLOCK ============
	s({
		trig = "lscomp",
		name = "Svelte Component Scaffold (Lua)",
		dscr = "Svelte component with script, markup, and styles",
		ft = { "svelte" },
	}, {
		t({ "<script>", '\texport let ' }),
		i(1, "props"),
		t({ ";", "</script>", "", "<div>", "\t" }),
		i(2, "<!-- component content -->"),
		t({ "", "</div>", "", "<style scoped>", "\t" }),
		i(3, "/* component styles */"),
		t({ "", "</style>" }),
	}),

	-- ============ SVELTE IF BLOCK ============
	s({
		trig = "lsif",
		name = "Svelte If Block (Lua)",
		dscr = "Svelte #if block",
		ft = { "svelte" },
	}, {
		t({ "{#if " }),
		i(1, "condition"),
		t({ "}", "\t" }),
		i(2, "<!-- content -->"),
		t({ "", "{/if}" }),
	}),

	-- ============ SVELTE EACH BLOCK ============
	s({
		trig = "lseach",
		name = "Svelte Each Block (Lua)",
		dscr = "Svelte #each loop",
		ft = { "svelte" },
	}, {
		t({ "{#each " }),
		i(1, "items"),
		t(" as "),
		i(2, "item"),
		t({ "}", "\t" }),
		i(3, "{item}"),
		t({ "", "{/each}" }),
	}),

	-- ============ BASIC SVELTE COMPONENT ============
	s({
		trig = "bscomp",
		name = "Basic Svelte Component (Lua)",
		dscr = "Basic Svelte component template",
		ft = { "svelte" },
	}, {
		t({ "<script>", '\texport let ' }),
		i(1, "props"),
		t({ ";", "</script>", "", "<div>", '\t' }),
		i(2, "<!-- component content -->"),
		t({ "", "</div>", "", "<style scoped>", '\t' }),
		i(3, "/* component styles */"),
		t({ "", "</style>" }),
	}),
}