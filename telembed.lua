local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local utils = require("telescope.utils")

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

local previewers = require("telescope.previewers")

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
	local corrected_str = string.gsub(result[1], "'", '"')
	-- Convert the corrected JSON string to a Lua table
	local lua_table = vim.fn.json_decode(corrected_str)

	Log("Finished json decode")
	Log(lua_table, true)

	local results = {}
	Log("\nBuilding updated list:")
	for _, line in ipairs(lua_table) do
		Log(line, true)
		local similarity = line[1]
		local filename = line[2]
		local linenum = line[3]
		local code = line[4]
		Log("Similarity: " .. tostring(similarity))
		Log("Filename: " .. tostring(filename))
		Log("Line number: " .. tostring(linenum))
		Log("Code: " .. tostring(code))
		table.insert(results, {
			value = code,
			ordinal = code,
			display = filename .. ":" .. linenum .. ": " .. code .. " (" .. similarity .. ")",
			filename = filename,
			lnum = linenum,
		})
	end

	Log("\nFinal result:")
	Log(results, true)

	return results
end

Log("Hello")

-- our picker function: colors
local colors = function(opts)
	opts = opts or {}
	pickers
		.new(opts, {
			prompt_title = "Semantic Search Query",
			--finder = finders.new_oneshot_job(get_semantic_search_output(opts[1], opts), opts),
			finder = finders.new_dynamic({
				fn = function(prompt_text, _)
					Log("1) Checking prompt guard: ")
					Log(prompt_text, true)
					if #prompt_text < 3 then -- Change this if you want a different minimum character requirement
						Log("Prompt guard failed")
						return {}
					end
					return get_semantic_search_output(prompt_text, opts)
				end,
				entry_maker = function(line)
					Log("\nGot line:")
					Log(line, true)
					return {
						value = line.filename,
						ordinal = line.filename,
						display = line.display,
					}
				end,
			}),
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
--get_semantic_search_output({}, {})
P("--------------------------------------------------")
