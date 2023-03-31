local M = {}

M.baseUrl = "https://api.openai.com/v1"
M._token = os.getenv("OPENAI_API_KEY")

local writeToBuffer = function(text)
    local pos = vim.api.nvim_win_get_cursor(0)

    local lines = vim.split(text, "\n")
    vim.api.nvim_put(lines, "c", false, true)
end


function curlOpenAI(endpoint, body)
    local curlCommand = table.concat({
        "curl -sL "..M.baseUrl..endpoint,
        "-H \"Content-Type: application/json\"",
        "-H \"Authorization: Bearer ".. M._token.."\"",
        "-d '"..vim.json.encode(body).."'"
    }, " ")

    local handle = io.popen(curlCommand)
    local result = handle:read("*a")
    handle:close()

    local res = vim.json.decode(result)

    return res.choices[1].text
end

M.getCompletion = function(text)
    local body = {
        model="text-davinci-003",
        prompt=text,
        max_tokens=256,
        temperature=0.1,
    }
    return curlOpenAI("/completions", body)
end

M.getEdit = function(text, prompt) 
    local body = {
        model="text-davinci-edit-001",
        input=text,
        instruction=prompt,
        temperature=0.1,
    }
    return curlOpenAI("/edits", body)
    end

M.editSelection = function (args)
    local buf = vim.api.nvim_get_current_buf()
    local start = vim.api.nvim_buf_get_mark(buf, "<")
    local stop =  vim.api.nvim_buf_get_mark(buf, ">")

    -- If visual line-mode, stop col will be too large.
    -- fix by grabbing everything up until col 0 on the row below
    -- TODO: do a cleaner fix
    if (stop[2] > 2000) then
        stop[2] = 0
        stop[1] = stop[1] + 1
    end

    local lines = vim.api.nvim_buf_get_text(
        buf,
        start[1]-1,
        start[2],
        stop[1]-1,
        stop[2],
        {}
    )
    local text = table.concat(lines, "\n")
    local instruction = args.args

    local result = M.getEdit(text, instruction)

    local resLines = vim.split(result, "\n")
    vim.api.nvim_buf_set_text(
        buf,
        start[1]-1,
        start[2],
        stop[1]-1,
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

return M

