local http = require("plenary.curl")

local M = {}

M.baseUrl = "https://api.openai.com/v1"
M._token = os.getenv("OPENAI_API_KEY")

local writeToBuffer = function(text)
    local pos = vim.api.nvim_win_get_cursor(0)

    local lines = vim.split(text, "\n")
    vim.api.nvim_put(lines, "c", false, true)
end


function curlOpenAI(q)
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. M._token,
    }

    local body = {
        model = "gpt-o-mini",
        messages = {
            {
                role = "user",
                content = q
            },
        }
    }
    local resp = http.post(M.base_url, {
        headers = headers,
        body = vim.fn.json_encode(body),
    })
    local data = vim.json.decode(resp.body)

    return data.choices[1].content
end

M.getCompletion = function(text)
    return curlOpenAI(text)
end

M.editSelection = function(args)
    local buf = vim.api.nvim_get_current_buf()
    local start = vim.api.nvim_buf_get_mark(buf, "<")
    local stop = vim.api.nvim_buf_get_mark(buf, ">")

    -- If visual line-mode, stop col will be too large.
    -- fix by grabbing everything up until col 0 on the row below
    -- TODO: do a cleaner fix
    if (stop[2] > 2000) then
        stop[2] = 0
        stop[1] = stop[1] + 1
    end

    local lines = vim.api.nvim_buf_get_text(
        buf,
        start[1] - 1,
        start[2],
        stop[1] - 1,
        stop[2],
        {}
    )
    local text = table.concat(lines, "\n")
    local instruction = args.args

    local result = M.getEdit(text, instruction)

    local resLines = vim.split(result, "\n")
    vim.api.nvim_buf_set_text(
        buf,
        start[1] - 1,
        start[2],
        stop[1] - 1,
        stop[2],
        resLines
    )
end

M.generateFromPrompt = function(args)
    local prompt = args.args
    local resp = M.getCompletion(prompt)
    writeToBuffer(resp)
end

M.complete = function()
    local buf = vim.api.nvim_get_current_buf()
    local pos = vim.api.nvim_win_get_cursor(0)

    local lines = vim.api.nvim_buf_get_lines(buf, 0, pos[1], false)
    local text = table.concat(lines, "\n")

    local resp = M.getCompletion(text)
    writeToBuffer(resp)
end

local function write_data_to_buf(output_buf)
    local data = "**This** is some *sample* output"

    local lc = vim.api.nvim_buf_line_count(output_buf)
    local l = vim.api.nvim_buf_get_lines(output_buf, lc - 1, lc, true)
    vim.api.nvim_buf_set_text(output_buf, lc - 1, #l[1], -1, -1, vim.split(data or "\n", "\n"))
end


local function process_input(prompt_buf, output_buf)
    local lines = vim.api.nvim_buf_get_lines(prompt_buf, 0, -1, false)

    local line_count = vim.api.nvim_buf_line_count(output_buf)
    vim.api.nvim_buf_set_lines(prompt_buf, 0, -1, true, { "" })

    lines[1] = "> " .. lines[1]
    -- local inp = utils.concat_tables({ "", string.rep("=", 80) }, lines, { "", "ai: " })
    vim.api.nvim_buf_set_lines(
        output_buf,
        line_count, -1,
        false,
        lines
    )
    write_data_to_buf(output_buf)
end


local output_buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_name(output_buf, "AI")
vim.api.nvim_set_option_value("filetype", "markdown", { buf = output_buf })

local prompt_buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_name(prompt_buf, "Prompt")


local output_win = vim.api.nvim_open_win(output_buf, true, { split = "right" })
vim.api.nvim_win_set_width(output_win, 100)

local prompt_win = vim.api.nvim_open_win(prompt_buf, true, { split = "below" })
vim.api.nvim_win_set_height(prompt_win, 5)

vim.keymap.set("n", "<CR>", function() process_input(prompt_buf, output_buf) end, { buffer = prompt_buf })


return M
