local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local utils = require("telescope.utils")
local previewers = require("telescope.previewers")

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

	-- Replace single quotes with double quotes and escape the inner double quotes
	--local corrected_str = string.gsub(result[1], "'", '"')
	--Log("\nCorrected String:")
	--Log(corrected_str, true)
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

Log("Hello")

local semantic_picker = function(opts)
	opts = opts or {}

	local function run_search(prompt_bufnr)
		local state = require("telescope.actions.state")
		Log(prompt_bufnr)
		local prompt_text = state.get_current_line(prompt_bufnr)
		Log(prompt_text)
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
			prompt_title = "Semantic Search Query (hit Enter to update search)",
			-- Initialize an empty job for now
			finder = finders.new_oneshot_job({}, opts),
			attach_mappings = function(_, map)
				map("i", "<cr>", function(prompt_bufnr)
					run_search(prompt_bufnr)
				end)

				-- needs to return true to map default_mappings
				return true
			end,
			-- use the default file previewer
			previewer = conf.file_previewer(opts),
		})
		:find()
end

semantic_picker(require("telescope.themes").get_dropdown({}))
P("--------------------------------------------------")
--get_semantic_search_output({}, {})
P("--------------------------------------------------")
