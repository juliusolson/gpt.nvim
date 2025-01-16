local http = require("plenary.curl")
local utils = require("utils")

local state = {
    prompt = { win = -1, buf = -1 },
    output = { win = -1, buf = -1 },
    conversation = {},
    result = { content = "", tokens = 0 },
}

local config = {
    model = "gpt-4o-mini",
    output_width = 100,
    prompt_height = 5,
    base_url = "https://api.openai.com/v1/chat/completions",
    layout = "split"
}


local function handle_chunk(_, chunk)
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
            state.result.content = state.result.content .. content
            state.result.tokens = state.result.tokens + 1
        end

        -- Write to buf
        utils.append_data_to_buf(content, state.output.buf)
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
        stream = handle_chunk,
        callback = function()
            vim.schedule(function()
                utils.append_data_to_buf(string.format("out tokens: ~%d", state.result.tokens), state.output.buf)
                table.insert(state.conversation, { role = "assistant", content = state.result.content })
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
    config = vim.tbl_deep_extend("force", config, opts)
    if opts.system_prompt then
        table.insert(state.conversation, { role = "system", content = opts.system_prompt })
    end
end

M.close = function()
    if vim.api.nvim_win_is_valid(state.output.win) then
        vim.api.nvim_win_close(state.output.win, false)
    end
    if vim.api.nvim_win_is_valid(state.prompt.win) then
        vim.api.nvim_win_close(state.prompt.win, false)
    end
end


local function open_windows(layout)
    if layout == "float" then
        local ui = vim.api.nvim_list_uis()[1]
        local total_height = ui.height
        local total_width = ui.width

        local output_width = math.floor(total_width * 0.75)
        local output_height = math.floor(total_height * 0.75)
        local offset = 5
        local output_r = math.floor((total_height - output_height) / 2 - offset)
        local output_c = math.floor((total_width - output_width) / 2)
        local prompt_height = 5
        local prommpt_r = output_r + output_height + 2

        state.output.win = vim.api.nvim_open_win(state.output.buf, true, {
            relative = 'editor',
            width = output_width,
            height = output_height,
            col = output_c,
            row = output_r,
            border = "rounded",
            style = "minimal",
            title = "AI (" .. config.model .. ")",
        })


        state.prompt.win = vim.api.nvim_open_win(state.prompt.buf, true, {
            relative = "editor",
            width = output_width,
            height = prompt_height,
            col = output_c,
            row = prommpt_r,
            border = "rounded",
            title = "Prompt",
        })
        return
    end

    if layout == "fullscreen" then
        vim.api.nvim_set_current_buf(state.output.buf)
    else
        state.output.win = vim.api.nvim_open_win(state.output.buf, true, { split = "right" })
        vim.api.nvim_win_set_width(state.output.win, config.output_width)
    end

    state.prompt.win = vim.api.nvim_open_win(state.prompt.buf, true, { split = "below" })
    vim.api.nvim_win_set_height(state.prompt.win, config.prompt_height)
end



local function set_model()
    vim.ui.input({ prompt = "Enter model you would like to use: " }, function(input)
        if input then
            config.model = input
            vim.api.nvim_win_set_config(state.output.win, { title = "AI (" .. config.model .. ")" })
        end
    end)
end

local function set_layout()
    local options = { "split", "float", "fullscreen" }
    vim.ui.select(options, {
        prompt = 'Choose an option: ',
        format_item = function(item) return item end
    }, function(selection)
        if selection then
            config.layout = selection
            M.close()
            M.open()
        end
    end)
end

M.open = function()
    if vim.api.nvim_win_is_valid(state.output.win) and vim.api.nvim_win_is_valid(state.prompt.win) then
        vim.api.nvim_set_current_win(state.prompt.win)
        return
    end

    if state.prompt.buf == -1 then
        create_bufs()
    end

    open_windows(config.layout)

    vim.keymap.set("n", "<CR>", function() process_input() end, { buffer = state.prompt.buf })
    vim.keymap.set("n", "q", function() M.close() end, { buffer = state.prompt.buf })
    vim.keymap.set("n", "q", function() M.close() end, { buffer = state.output.buf })
    vim.keymap.set("n", "M", function() set_model() end, { buffer = state.prompt.buf })
    vim.keymap.set("n", "L", function() set_layout() end, { buffer = state.prompt.buf })
end

return M
