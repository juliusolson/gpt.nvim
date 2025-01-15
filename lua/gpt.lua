local http = require("plenary.curl")
local utils = require("utils")

local state = {
    open = false,
    prompt = { win = -1, buf = -1 },
    output = { win = -1, buf = -1 },
    conversation = {
        {
            role = "system",
            content = "You are a helpful assistant. You will answer question as concise as possible"
        }
    },
    result = "",
}

local config = {
    model = "gpt-4o-mini",
    output_width = 100,
    prompt_height = 5,
    base_url = "https://api.openai.com/v1/chat/completions"
}


local function write_data_to_buf(data)
    local lc = vim.api.nvim_buf_line_count(state.output.buf)
    local l = vim.api.nvim_buf_get_lines(state.output.buf, lc - 1, lc, true)
    vim.api.nvim_buf_set_text(state.output.buf, lc - 1, #l[1], -1, -1, vim.split(data or "\n", "\n"))
end


local function streamfun(_, chunk)
    vim.schedule(function()
        if chunk == nil or chunk == "" then
            return
        end

        local prefix = "data: "
        local data = string.sub(chunk, #prefix + 1)

        if data == "[DONE]" then
            return
        end

        local payload = vim.fn.json_decode(data)
        local content = payload.choices[1].delta.content

        -- Append content to current chat result
        if content then
            state.result = state.result .. content
        end

        -- Write to buf
        write_data_to_buf(content)
        vim.cmd("redraw")
    end)
end


local function get_answer(q)
    local apikey = os.getenv("OPENAI_API_KEY") or ""
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. apikey,
    }
    table.insert(state.conversation, {
        role = "user",
        content = q
    })
    local body = {
        stream = true,
        model = config.model,
        messages = state.conversation,
    }
    local resp = http.post(config.base_url, {
        headers = headers,
        body = vim.fn.json_encode(body),
        stream = streamfun,
        callback = function()
            vim.schedule(function()
                table.insert(state.conversation, { role = "assistant", content = state.result })
            end)
        end,
    })
    return resp
end

local function process_input()
    local lines = vim.api.nvim_buf_get_lines(state.prompt.buf, 0, -1, false)

    if #lines < 1 then
        return
    end

    local raw_user_input = table.concat(lines, "\n")
    local user_input = string.gsub(raw_user_input, "/paste", vim.fn.getreg('"'))

    vim.api.nvim_buf_set_lines(state.prompt.buf, 0, -1, true, { "" })

    lines[1] = "> " .. lines[1]
    local inp = utils.concat_tables({ "", string.rep("=", 80) }, lines, { "", "ai: " })

    local line_count = vim.api.nvim_buf_line_count(state.output.buf)
    vim.api.nvim_buf_set_lines(
        state.output.buf,
        line_count, -1,
        false,
        inp
    )
    get_answer(user_input)
end

local function create_bufs()
    state.output.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(state.output.buf, "AI")
    vim.api.nvim_set_option_value("filetype", "markdown", { buf = state.output.buf })

    state.prompt.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(state.prompt.buf, "Prompt")
end

local M = {}

M.setup = function(opts)
    opts = opts or {}
    opts.model = opts.model or config.model
    opts.output_width = opts.output_width or config.output_width
    opts.prompt_height = opts.prompt_height or config.prompt_height
    opts.base_url = opts.base_url or config.base_url
    config = opts
end

M.close = function()
    vim.api.nvim_win_close(state.output.win, false)
    vim.api.nvim_win_close(state.prompt.win, false)
    state.open = false
end


M.open = function()
    if state.open then
        vim.api.nvim_set_current_win(state.prompt.win)
        return
    end
    state.open = true

    if state.prompt.buf == -1 then
        create_bufs()
    end

    state.output.win = vim.api.nvim_open_win(state.output.buf, true, { split = "right" })
    vim.api.nvim_win_set_width(state.output.win, config.output_width)

    state.prompt.win = vim.api.nvim_open_win(state.prompt.buf, true, { split = "below" })
    vim.api.nvim_win_set_height(state.prompt.win, config.prompt_height)


    vim.keymap.set("n", "<CR>", function() process_input() end, { buffer = state.prompt.buf })
    vim.keymap.set("n", "q", function() M.close() end, { buffer = state.prompt.buf })
end

return M
