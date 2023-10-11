local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local utils = require("telescope.utils")
local themes = require("telescope.themes")

Log = function(x, inspect)
	inspect = inspect or false
	local file = io.open("./jake-telescope.log", "a")
	if file == nil then
		print("Could not open file")
		return
	end

	file:write(tostring(x) .. "\n")
	file:close()

	if inspect then
		Log(vim.inspect(x))
	end
end

P = function(x, inspect)
	inspect = inspect or false
	vim.api.nvim_echo({ { tostring(x), "None" } }, false, {})

	if inspect then
		P(vim.inspect(x))
	end
end

local get_semantic_search_output = function(args, opts)
	Log("Getting the semantic search output")
	local result =
		utils.get_os_command_output({ "/Users/eagle/reddy/semantic-code-search/venv/bin/sem", args }, opts.cwd)
	Log("Finished processing the semantic search output")
	Log(result, true)
	Log("Parsing the semantic search output")
	Log(result[1], true)

	-- Convert the corrected JSON string to a Lua table
	local lua_table = vim.fn.json_decode(result[1])

	Log("Finished json decode")
	Log(lua_table, true)

	local results = {}
	Log("\nBuilding updated list:")
	for _, line in ipairs(lua_table) do
		Log(line, true)
		local similarity = math.floor(line[1] * 10000)
		local filename = line[2]
		local short_filename = filename:match("([^/]+)$")
		local linenum = line[3]
		local code = line[4]
		Log("Similarity: " .. tostring(similarity))
		Log("Filename: " .. tostring(filename))
		Log("Line number: " .. tostring(linenum))
		Log("Code: " .. tostring(code))
		table.insert(results, {
			value = code,
			ordinal = similarity,
			display = short_filename .. ":" .. linenum .. ": " .. code .. " (" .. similarity .. ")",
			filename = filename,
			lnum = linenum,
		})
	end

	Log("\nFinal result:")
	Log(results, true)

	return results
end

local semantic_picker = function(opts)
	opts = opts or {}

	local function run_search(prompt_bufnr)
		local state = require("telescope.actions.state")
		local prompt_text = state.get_current_line(prompt_bufnr)
		if #prompt_text < 3 then -- Change this if you want a different minimum character requirement
			Log("Prompt guard failed")
			return {}
		end
		local search_results = get_semantic_search_output(prompt_text, opts)
		-- Set the picker results to the search results
		local picker = state.get_current_picker(prompt_bufnr)
		picker.finder = finders.new_table({
			results = search_results,
			entry_maker = function(line)
				Log("\nGot line:")
				Log(line, true)
				return {
					value = line.filename,
					ordinal = line.ordinal,
					display = line.display,
					code = line.value,
				}
			end,
		})
		picker:refresh()
	end

	pickers
		.new(opts, {
			prompt_title = "Semantic Search Query",
			-- Initialize the finder with an empty table
			finder = finders.new_oneshot_job({}, opts),
			-- use the default file previewer
			attach_mappings = function(_, map)
				map("i", "<cr>", function(prompt_bufnr)
					run_search(prompt_bufnr)
				end)
				map("n", "<cr>", function(prompt_bufnr)
					run_search(prompt_bufnr)
				end)

				-- needs to return true to map default_mappings
				return true
			end,
			previewer = conf.file_previewer(opts),
		})
		:find()
end

--local previewers = require("telescope.previewers")
--
--local new_maker = function(filepath, bufnr, opts)
--	opts = opts or {}
--
--	filepath = vim.fn.expand(filepath)
--	vim.loop.fs_stat(filepath, function(_, stat)
--		if not stat then
--			return
--		end
--		if stat.size > 100000 then
--			return
--		else
--			previewers.buffer_previewer_maker(filepath, bufnr, opts)
--		end
--	end)
--end

--semantic_picker(themes.get_dropdown({}))
semantic_picker(require("telescope.themes").get_dropdown({}))

--semantic_picker(themes.get_ivy({
--
--	buffer_previewer_maker = new_maker,
--	-- see: https://github.com/nvim-telescope/telescope.nvim/issues/1379#issuecomment-996590765
--	preview = {
--		treesitter = false,
--	},
--	log_level = "debug",
--	mappings = {
--		i = {
--			["<C-c>"] = require("telescope.actions").close,
--		},
--		n = {
--			["<C-c>"] = require("telescope.actions").close,
--		},
--	},
--	--layout_strategy = "vertical",
--	--layout_config = {
--	--	width = 0.9,
--	--	height = 0.9,
--	--	prompt_position = "bottom",
--	--},
--}))

P("--------------------------------------------------")
--get_semantic_search_output({}, {})
P("--------------------------------------------------")
