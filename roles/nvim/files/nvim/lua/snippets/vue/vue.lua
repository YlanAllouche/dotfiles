local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
	-- ============ VUE COMPONENT ============
	s({
		trig = "lvcomp",
		name = "Vue Component Scaffold (Lua)",
		dscr = "Basic Vue SFC component structure",
		ft = { "vue" },
	}, {
		t({ "<template>", "\t<div>", "\t\t" }),
		i(1, "<!-- template -->"),
		t({ "", "\t</div>", "</template>", "", "<script setup>", "\t" }),
		i(2, "// script"),
		t({ "", "</script>", "", "<style scoped>", "\t" }),
		i(3, "/* styles */"),
		t({ "", "</style>" }),
	}),

	-- ============ VUE V-IF ============
	s({
		trig = "lvif",
		name = "Vue v-if (Lua)",
		dscr = "Vue v-if directive",
		ft = { "vue" },
	}, {
		t("v-if=\""),
		i(1, "condition"),
		t('"'),
	}),

	-- ============ VUE V-FOR ============
	s({
		trig = "lvfor",
		name = "Vue v-for (Lua)",
		dscr = "Vue v-for directive",
		ft = { "vue" },
	}, {
		t("v-for=\""),
		i(1, "item"),
		t(" in "),
		i(2, "items"),
		t('"'),
	}),

	-- ============ VUE REACTIVE ============
	s({
		trig = "lvref",
		name = "Vue ref (Lua)",
		dscr = "Vue ref() for reactive variable",
		ft = { "vue" },
	}, {
		t("const "),
		i(1, "variable"),
		t(" = ref("),
		i(2, "null"),
		t(");"),
	}),
}
