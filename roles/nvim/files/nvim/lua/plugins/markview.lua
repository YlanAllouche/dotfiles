return {
	"OXY2DEV/markview.nvim",
	config = function()
		require("markview").setup({
			preview = {
				filetypes = { "markdown", "codecompanion" },
				enable = true,
				max_buf_lines = 1000000,
				draw_range = { 1000000, 1000000 },
				modes = { "n", "no", "c", "i", "v", "V" },
				hybrid_modes = {},
				enable_hybrid_mode = false,
			},
			-- Custom header styling with bullet points
			markdown = {
				headings = {
					enable = true,
					heading_1 = {
						style = "icon", -- Use icon style
						icon = "◉ ", -- Big filled circle for H1
						hl = "MarkviewHeading1",
						padding_left = "", -- No padding
					},
					heading_2 = {
						style = "icon",
						icon = "● ", -- Medium filled circle for H2
						hl = "MarkviewHeading2",
						padding_left = "",
					},
					heading_3 = {
						style = "icon",
						icon = "○ ", -- Medium empty circle for H3
						hl = "MarkviewHeading3",
						padding_left = "",
					},
					heading_4 = {
						style = "icon",
						icon = "◆ ", -- Diamond for H4
						hl = "MarkviewHeading4",
						padding_left = "",
					},
					heading_5 = {
						style = "icon",
						icon = "◇ ", -- Empty diamond for H5
						hl = "MarkviewHeading5",
						padding_left = "",
					},
					heading_6 = {
						style = "icon",
						icon = "▪ ", -- Square for H6
						hl = "MarkviewHeading6",
						padding_left = "",
					},
					shift_width = 0, -- No shift width for headers
				},
				-- Customize list items with • character
				list_items = {
					enable = true,
					wrap = true,
					indent_size = 3, -- Smaller indent
					shift_width = 1, -- Smaller shift
					marker_minus = {
						add_padding = false,
						conceal_on_checkboxes = true,
						text = "•", -- Changed to bullet
						hl = "MarkviewListItemMinus",
					},
					marker_plus = {
						add_padding = true,
						conceal_on_checkboxes = true,
						text = "• ", -- Changed to bullet
						hl = "MarkviewListItemPlus",
					},
					marker_star = {
						add_padding = true,
						conceal_on_checkboxes = true,
						text = "• ", -- Changed to bullet
						hl = "MarkviewListItemStar",
					},
				},
			},
			markdown_inline = {
				checkboxes = {
					enable = true,
					-- Checked items with strikethrough
					checked = {
						text = "󰄲 ", -- "✅",
						hl = "MarkviewCheckboxChecked",
						scope_hl = "MarkviewCheckboxStriked",
					},
					unchecked = {
						text = "󰄱 ", -- ""⬜",
						hl = "MarkviewCheckboxUnchecked",
						scope_hl = "MarkviewCheckboxUnchecked",
					},
					["p"] = { text = "🔄", hl = "MarkviewCheckboxPending" },
					["!"] = { text = "⚠️", hl = "MarkviewCheckboxUnchecked" },
				},
				-- For hyperlinks (web URLs and dataview properties)
				hyperlinks = {
					enable = true,
					default = {
						icon = "🔗 ",
						hl = "MarkviewHyperlink",
					},
					-- Web URLs with http/https
					["^https?://"] = {
						icon = "🌐 ",
						hl = "MarkviewPalette5Fg",
					},
					-- All dataview properties with the same background color
					["completion::"] = {
						icon = "⏰ ",
						hl = "MarkviewDataviewField",
					},
					["due::"] = {
						icon = "⏰ ",
						hl = "MarkviewDataviewField",
					},
					["deadline::"] = {
						icon = "⏰ ",
						hl = "MarkviewDataviewField",
					},
					["priority::"] = {
						icon = "🔥 ",
						hl = "MarkviewDataviewField",
					},
					["tags::"] = {
						icon = "🏷️ ",
						hl = "MarkviewDataviewField",
					},
					["status::"] = {
						icon = "📊 ",
						hl = "MarkviewDataviewField",
					},
				},
				-- For internal links (wiki-style)
				internal_links = {
					enable = true,
					default = {
						icon = "🔗 ",
						hl = "MarkviewPalette7Fg",
					},
				},
				-- Also update URI autolinks for web URLs
				uri_autolinks = {
					enable = true,
					default = {
						icon = "🔗 ",
						hl = "MarkviewEmail",
					},
					["^https?://"] = {
						icon = "🌐 ",
						hl = "MarkviewPalette5Fg",
					},
				},
			},
			-- YAML configuration for frontmatter
			yaml = {
				enable = true,
				properties = {
					enable = true,
					data_types = {
						["text"] = {
							text = "󰗊 ",
							hl = "MarkviewIcon4",
						},
						["list"] = {
							text = "󰝖 ",
							hl = "MarkviewIcon5",
						},
						["number"] = {
							text = " ",
							hl = "MarkviewIcon6",
						},
						["checkbox"] = {
							text = function(_, item)
								return item.value == "true" and "󰄲 " or "󰄱 "
							end,
							hl = "MarkviewIcon6",
						},
						["date"] = {
							text = "󰃭 ",
							hl = "MarkviewIcon2",
						},
						["date_&_time"] = {
							text = "󰥔 ",
							hl = "MarkviewIcon3",
						},
					},
					default = {
						use_types = true,
						border_top = " │ ",
						border_middle = " │ ",
						border_bottom = " ╰╸",
						border_hl = "MarkviewComment",
						text = "📄 ",
						hl = "MarkviewYamlProperty",
					},
					-- Custom YAML field configurations
					["^type$"] = {
						match_string = "^type$",
						use_types = false,
						text = "🏷️ ",
						hl = "MarkviewYamlType",
					},
					["^class$"] = {
						match_string = "^class$",
						use_types = false,
						text = "🔖 ",
						hl = "MarkviewYamlClass",
					},
					["^children$"] = {
						match_string = "^children$",
						use_types = false,
						text = "👪 ",
						hl = "MarkviewYamlChildren",
					},
					["^topic$"] = {
						match_string = "^topic$",
						use_types = false,
						text = "📌 ",
						hl = "MarkviewYamlTopic",
					},
					["^area$"] = {
						match_string = "^area$",
						use_types = false,
						text = "🗺️ ",
						hl = "MarkviewYamlArea",
					},
					["^material$"] = {
						match_string = "^material$",
						use_types = false,
						text = "🧱 ",
						hl = "MarkviewYamlMaterial",
					},
					["^title$"] = {
						match_string = "^title$",
						use_types = false,
						text = "📝 ",
						hl = "MarkviewYamlTitle",
					},
					["^id$"] = {
						match_string = "^id$",
						use_types = false,
						text = "🆔 ",
						hl = "MarkviewYamlId",
					},
					["^url$"] = {
						match_string = "^url$",
						use_types = false,
						text = "🔗 ",
						hl = "MarkviewYamlUrl",
					},
					["^thumbnail$"] = {
						match_string = "^thumbnail$",
						use_types = false,
						text = "🖼️ ",
						hl = "MarkviewYamlThumbnail",
					},
					["^tags$"] = {
						match_string = "^tags$",
						use_types = false,
						text = "🏷️ ",
						hl = "MarkviewYamlTags",
					},
					["^aliases$"] = {
						match_string = "^aliases$",
						use_types = false,
						text = "📎 ",
						hl = "MarkviewYamlAliases",
					},
					["^cssclasses$"] = {
						match_string = "^cssclasses$",
						use_types = false,
						text = "🎨 ",
						hl = "MarkviewYamlCssClasses",
					},
					["^publish$"] = {
						match_string = "^publish$",
						use_types = false,
						text = "📢 ",
						hl = "MarkviewYamlPublish",
					},
					["^permalink$"] = {
						match_string = "^permalink$",
						use_types = false,
						text = "🔒 ",
						hl = "MarkviewYamlPermalink",
					},
					["^description$"] = {
						match_string = "^description$",
						use_types = false,
						text = "📋 ",
						hl = "MarkviewYamlDescription",
					},
					["^image$"] = {
						match_string = "^image$",
						use_types = false,
						text = "🖼️ ",
						hl = "MarkviewYamlImage",
					},
					["^cover$"] = {
						match_string = "^cover$",
						use_types = false,
						text = "🌄 ",
						hl = "MarkviewYamlCover",
					},
				},
			},
			-- Custom renderers for list items
			renderers = {
				markdown = {
					markdown_list_item = function(node, ctx)
						local list_type = node.list_type
						if list_type == "bullet" then
							-- Get the depth of the list item
							local depth = node.depth or 1
							local indent = string.rep("  ", depth - 1)
							-- Add bullet with proper indentation
							ctx:append_text(indent .. "• ", "MarkviewListItemMinus")
							-- Render the content of the list item
							ctx:render_children(node)
							return true
						end
						return false -- Let default renderer handle other types
					end,
					-- Custom renderer for hyperlinks to add background color
					inline_link_hyperlink = function(node, ctx)
						local label = node.label or ""
						local destination = node.destination or ""
						-- Check if this is a dataview field
						if destination:match("^[%w%-_]+::") then
							-- Add background color for dataview fields
							ctx:append_text("[", "Normal")
							ctx:append_text(label, "MarkviewDataviewField")
							ctx:append_text("]", "Normal")
							ctx:append_text("(", "Normal")
							ctx:append_text(destination, "MarkviewDataviewField")
							ctx:append_text(")", "Normal")
							return true
						end
						-- For web URLs
						if destination:match("^https?://") then
							ctx:append_text("🌐 ", "MarkviewPalette5Fg")
							ctx:append_text(label, "MarkviewPalette5Fg")
							return true
						end
						-- Return false to use default rendering for other links
						return false
					end,
				},
			},
			-- Define custom highlight groups for our styling
			on_attach = function()
				-- Create highlight groups for headers and other elements
				vim.cmd([[
          " Header highlight groups with bold styling
          highlight MarkviewHeading1 guifg=#1e90ff gui=bold
          highlight MarkviewHeading2 guifg=#9370db gui=bold
          highlight MarkviewHeading3 guifg=#3cb371 gui=bold
          highlight MarkviewHeading4 guifg=#ff8c00 gui=bold
          highlight MarkviewHeading5 guifg=#da70d6 gui=bold
          highlight MarkviewHeading6 guifg=#cd5c5c gui=bold
          " Strikethrough for completed tasks
          highlight MarkviewCheckboxStriked gui=strikethrough guifg=#888888
          " Dataview field highlight with background color
          highlight MarkviewDataviewField guifg=#000000 guibg=#e0f0ff gui=bold
          
          " YAML frontmatter highlight groups
          highlight MarkviewYamlProperty guifg=#7e7eff gui=bold
          highlight MarkviewYamlType guifg=#ff7e7e gui=bold
          highlight MarkviewYamlClass guifg=#7eff7e gui=bold
          highlight MarkviewYamlChildren guifg=#ff7eff gui=bold
          highlight MarkviewYamlTopic guifg=#ffaa7e gui=bold
          highlight MarkviewYamlArea guifg=#7effff gui=bold
          highlight MarkviewYamlMaterial guifg=#ff7e7e gui=bold
          highlight MarkviewYamlTitle guifg=#ffff7e gui=bold
          highlight MarkviewYamlId guifg=#7e7eff gui=bold
          highlight MarkviewYamlUrl guifg=#7effaa gui=bold
          highlight MarkviewYamlThumbnail guifg=#ff7eaa gui=bold
          highlight MarkviewYamlTags guifg=#ffaa7e gui=bold
          highlight MarkviewYamlAliases guifg=#aa7eff gui=bold
          highlight MarkviewYamlCssClasses guifg=#7effff gui=bold
          highlight MarkviewYamlPublish guifg=#ff7e7e gui=bold
          highlight MarkviewYamlPermalink guifg=#7eff7e gui=bold
          highlight MarkviewYamlDescription guifg=#7e7eff gui=bold
          highlight MarkviewYamlImage guifg=#ff7eaa gui=bold
          highlight MarkviewYamlCover guifg=#ffff7e gui=bold
        ]])
				-- Setup folding for markdown files
				if vim.bo.filetype == "markdown" then
					-- Removes the ••• part
					vim.o.fillchars = "fold: "
					vim.o.foldmethod = "expr"
					vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
					-- Set up custom fold text function
					vim.o.foldtext = "v:lua.heading_foldtext()"
				end
			end,
		})
		-- Define the custom fold text function
		vim.keymap.set("n", "<leader>mm", ":Markview toggle<CR>", { noremap = true, silent = true })
		_G.heading_foldtext = function()
			-- Start & end of the current fold
			local from, to = vim.v.foldstart, vim.v.foldend
			-- Starting line
			local line = vim.api.nvim_buf_get_lines(0, from - 1, from, false)[1]
			if line:match("^[%s%>]*%#+") == nil then
				-- Fold didn't start on a heading
				return vim.fn.foldtext()
			end
			-- Indentation, markers & the content of a heading
			local indent, marker, content = line:match("^([%s%>]*)(%#+)(.*)$")
			-- Heading level
			local level = marker:len()
			-- Get the icon based on heading level
			local icon = "◉ " -- Default icon
			if level == 1 then
				icon = "● "
			elseif level == 2 then
				icon = "◙ "
			elseif level == 3 then
				icon = "○ "
			elseif level == 4 then
				icon = "◆ "
			elseif level == 5 then
				icon = "◇ "
			elseif level == 6 then
				icon = "▪ "
			end
			-- Get highlight group for this heading level
			local hl_group = "MarkviewHeading" .. level
			-- Format the fold text
			return {
				{ icon, { fg = vim.api.nvim_get_hl(0, { name = hl_group }).fg } },
				{ content:gsub("^%s", ""), { fg = vim.api.nvim_get_hl(0, { name = hl_group }).fg } },
				{ string.format(" [%d lines]", to - from), { fg = "#888888" } },
			}
		end
	end,
	-- Additional setup to create the required folding query file
	init = function()
		-- Create the folding query file if it doesn't exist
		local query_dir = vim.fn.stdpath("config") .. "/queries/markdown"
		local query_file = query_dir .. "/folds.scm"
		if vim.fn.filereadable(query_file) == 0 then
			-- Create directory if it doesn't exist
			if vim.fn.isdirectory(query_dir) == 0 then
				vim.fn.mkdir(query_dir, "p")
			end
			-- Write the query content
			local query_content = [[
Folds a section of the document that starts with a heading
((section
    (atx_heading)) @fold
    (#trim! @fold))

; Folds lists and their items
(list
  (list_item) @fold
  (#trim! @fold))

; Folds nested list items
(list_item
  (list) @fold
  (#trim! @fold))
]]

			local file = io.open(query_file, "w")
			if file then
				file:write(query_content)
				file:close()
				print("Created markdown folding query file at: " .. query_file)
			else
				print("Failed to create markdown folding query file")
			end
		end
	end,
}
