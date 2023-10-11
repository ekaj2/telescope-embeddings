local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local previewers = require("telescope.previewers")

-- our picker function: colors
local colors = function(opts)
	opts = opts or {}
	pickers
		.new(opts, {
			prompt_title = "Semantic Search Query",
			finder = finders.new_table({
				results = {
					{ "red", "#ff0000" },
					{ "green", "#00ff00" },
					{ "blue", "#0000ff" },
				},
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry[1],
						ordinal = entry[1],
					}
				end,
			}),
			sorter = conf.generic_sorter(opts),
			--Or:
			--sorter = conf.file_sorter(opts),
			previewer = previewers.new_buffer_previewer({
				define_preview = function(self, entry, status)
					self.state.bufnr = vim.api.nvim_create_buf(false, true)
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { entry[2] })
				end,
			}),
		})
		:find()
end

-- to execute the function
--colors()
colors(require("telescope.themes").get_dropdown({}))
