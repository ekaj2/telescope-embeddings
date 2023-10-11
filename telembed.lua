local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local utils = require("telescope.utils")

local previewers = require("telescope.previewers")

P = function(x, inspect)
	inspect = inspect or false
	vim.api.nvim_echo({ { tostring(x), "None" } }, false, {})

	if inspect then
		P(vim.inspect(x))
	end
end

local get_semantic_search_output = function(args, opts)
	P(opts, true)
	-- .. args[1] may be the prompt?
	-- print out this result
	P("Getting the semantic search output")
	local result = utils.get_os_command_output(
		{ "/Users/eagle/reddy/semantic-code-search/venv/bin/sem", "where do I get the mean" },
		opts.cwd
	)
	P(result, true)
	--local cmd = { "find", ".", "-type", "f", "-name", "*.*" }
	local cmd = { "/Users/eagle/reddy/semantic-code-search/venv/bin/sem", "where do I get the mean" }
	--return cmd
end

-- our picker function: colors
local colors = function(opts)
	opts = opts or {}
	pickers
		.new(opts, {
			prompt_title = "Semantic Search Query",
			finder = finders.new_oneshot_job(get_semantic_search_output(opts[1], opts), opts),
			-- finder = finders.new_table({
			-- 	results = {
			-- 		{ "red", "#ff0000" },
			-- 		{ "green", "#00ff00" },
			-- 		{ "blue", "#0000ff" },
			-- 	},
			-- 	entry_maker = function(entry)
			-- 		return {
			-- 			value = entry,
			-- 			display = entry[1],
			-- 			ordinal = entry[1],
			-- 		}
			-- 	end,
			-- }),
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

colors(require("telescope.themes").get_dropdown({}))
P("--------------------------------------------------")
get_semantic_search_output({}, {})
P("--------------------------------------------------")
