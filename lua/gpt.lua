local http = require("plenary.curl")

local state = {
    prompt = { win = -1, buf = -1 },
    output = { win = -1, buf = -1 },
}

local config = {
    model = "gpt-4o-mini",
    output_width = 100,
    prompt_height = 5,
    base_url = "https://api.openai.com/v1/chat/completions"
}

local M = {}

M._token = os.getenv("OPENAI_API_KEY")


local function write_data_to_buf(data)
    data = data or "**This** is some *sample* output"

    local lc = vim.api.nvim_buf_line_count(state.output.buf)
    local l = vim.api.nvim_buf_get_lines(state.output.buf, lc - 1, lc, true)
    vim.api.nvim_buf_set_text(state.output.buf, lc - 1, #l[1], -1, -1, vim.split(data or "\n", "\n"))
end

local function curl_openai(q)
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. M._token,
    }

    local body = {
        model = config.model,
        messages = {
            {
                role = "user",
                content = q
            },
        }
    }
    local resp = http.post(config.base_url, {
        headers = headers,
        body = vim.fn.json_encode(body),
    })
    local data = vim.json.decode(resp.body)

    return data.choices[1].content
end

M.getCompletion = function(text)
    return curl_openai(text)
end

M.generateFromPrompt = function(args)
    local prompt = args.args
    local resp = M.getCompletion(prompt)
    write_data_to_buf(resp)
end

local function process_input()
    local lines = vim.api.nvim_buf_get_lines(state.prompt.buf, 0, -1, false)

    local line_count = vim.api.nvim_buf_line_count(state.output.buf)
    vim.api.nvim_buf_set_lines(state.prompt.buf, 0, -1, true, { "" })

    lines[1] = "> " .. lines[1]
    -- local inp = utils.concat_tables({ "", string.rep("=", 80) }, lines, { "", "ai: " })
    vim.api.nvim_buf_set_lines(
        state.output.buf,
        line_count, -1,
        false,
        lines
    )
    write_data_to_buf(nil)
end


local function new_flow()
    state.output.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(state.output.buf, "AI")
    vim.api.nvim_set_option_value("filetype", "markdown", { buf = state.output.buf })

    state.prompt.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(state.prompt.buf, "Prompt")


    state.output.win = vim.api.nvim_open_win(state.output.buf, true, { split = "right" })
    vim.api.nvim_win_set_width(state.output.win, config.output_width)

    state.prompt.win = vim.api.nvim_open_win(state.prompt.buf, true, { split = "below" })
    vim.api.nvim_win_set_height(state.prompt.win, config.prompt_height)

    vim.keymap.set("n", "<CR>", function() process_input() end, { buffer = state.prompt.buf })
end

-- new_flow()

return M
