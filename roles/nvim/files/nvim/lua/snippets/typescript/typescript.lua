local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

return {
	-- ============ CONSOLE.LOG ============
	-- Simple console.log with variable placeholder
	s({
		trig = "lclg",
		name = "Console Log (Lua)",
		dscr = "Basic console.log snippet",
		ft = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
	}, {
		t("console.log("),
		i(1, "variable"),
		t(");"),
	}),

	-- ============ ARROW FUNCTION ============
	-- Arrow function with JSDoc comment
	s({
		trig = "larfn",
		name = "Arrow Function (Lua)",
		dscr = "Arrow function with JSDoc documentation",
		ft = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
	}, {
		t({ "/**", " * " }),
		i(1, "functionName"),
		t({ "", " */", "const " }),
		f(function(args)
			return args[1][1]
		end, { 1 }),
		t(" = ("),
		i(2, "params"),
		t({ ") => {", "\t" }),
		i(3, "// body"),
		t({ "", "};" }),
	}),

	-- ============ USESTATE HOOK ============
	-- React useState with automatic setter name transformation
	s({
		trig = "lust",
		name = "useState Hook (Lua)",
		dscr = "React useState hook with automatic setter naming (capitalize first letter)",
		ft = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
	}, {
		t("const ["),
		i(1, "count"),
		t(", set"),
		f(function(args)
			local var_name = args[1][1]
			-- Capitalize first letter
			return var_name:sub(1, 1):upper() .. var_name:sub(2)
		end, { 1 }),
		t("] = useState("),
		i(2, "0"),
		t(");"),
	}),

	-- ============ USEEFFECT HOOK ============
	-- React useEffect hook
	s({
		trig = "luef",
		name = "useEffect Hook (Lua)",
		dscr = "React useEffect hook with dependency array",
		ft = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
	}, {
		t({ "useEffect(() => {", "\t" }),
		i(1, "// effect"),
		t({ "", "}, [" }),
		i(2, "dependency"),
		t("]);"),
	}),

	-- ============ USEREF HOOK ============
	-- React useRef hook
	s({
		trig = "lurf",
		name = "useRef Hook (Lua)",
		dscr = "React useRef hook",
		ft = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
	}, {
		t("const "),
		i(1, "ref"),
		t(" = useRef("),
		i(2, "null"),
		t(");"),
	}),

	-- ============ TRY-CATCH BLOCK ============
	-- Basic try-catch (VSCode-compatible version)
	s({
		trig = "ltryc",
		name = "Try-Catch Block (Lua)",
		dscr = "Basic try-catch error handling",
		ft = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
	}, {
		t({ "try {", "\t" }),
		i(1, "// code"),
		t({ "", "} catch (error) {", "\t" }),
		i(2, "console.error(error);"),
		t({ "", "}" }),
	}),

	-- ============ ASYNC FUNCTION ============
	-- Async arrow function
	s({
		trig = "larfnasync",
		name = "Async Arrow Function (Lua)",
		dscr = "Async arrow function",
		ft = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
	}, {
		t("const "),
		i(1, "functionName"),
		t(" = async ("),
		i(2, "params"),
		t({ ") => {", "\t" }),
		i(3, "// body"),
		t({ "", "};" }),
	}),

	-- ============ PROMISE THEN ============
	-- Promise .then() chain
	s({
		trig = "lprom",
		name = "Promise .then() (Lua)",
		dscr = "Promise with .then() and .catch()",
		ft = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
	}, {
		i(1, "promise"),
		t({ ".then((result) => {", "\t" }),
		i(2, "console.log(result);"),
		t({ "", "})", ".catch((error) => {", "\t" }),
		i(3, "console.error(error);"),
		t({ "", "})" }),
	}),
}, {
	-- ============ AUTOSNIPPETS ============
	-- These trigger without needing a space
	s({
		trig = "lcl",
		name = "Quick Console Log (Lua)",
		dscr = "Quick console.log without full name",
		ft = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
		wordTrig = false,
	}, {
		t("console.log("),
		i(1),
		t(");"),
	}),
}
