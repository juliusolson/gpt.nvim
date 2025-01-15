local http = require("plenary.curl")

local M = {}

local config = {
    model = "gpt-4o-mini",
    output_width = 100,
    prompt_height = 5,
    base_url = "https://api.openai.com/v1/chat/completions"
}

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
    return curlOpenAI(text)
end

M.generateFromPrompt = function(args)
    local prompt = args.args
    local resp = M.getCompletion(prompt)
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


local function new_flow()
    local output_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(output_buf, "AI")
    vim.api.nvim_set_option_value("filetype", "markdown", { buf = output_buf })

    local prompt_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(prompt_buf, "Prompt")


    local output_win = vim.api.nvim_open_win(output_buf, true, { split = "right" })
    vim.api.nvim_win_set_width(output_win, config.output_width)

    local prompt_win = vim.api.nvim_open_win(prompt_buf, true, { split = "below" })
    vim.api.nvim_win_set_height(prompt_win, config.prompt_height)

    vim.keymap.set("n", "<CR>", function() process_input(prompt_buf, output_buf) end, { buffer = prompt_buf })
end

-- new_flow()

return M
