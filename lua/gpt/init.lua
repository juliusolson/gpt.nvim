local M = {}


M.getLines = function() 
    local buf = vim.api.nvim_get_current_buf()
    local pos = vim.api.nvim_win_get_cursor(0)

    -- Get the lines of text that are within the selection
    local lines = vim.api.nvim_buf_get_lines(buf, 0, pos[1], false)
    local text = table.concat(lines, "\n")
    return text
end

function curlOpenAI(command) 
    local handle = io.popen(command)
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
    local bodyStr = vim.json.encode(body)

    local command_template = [[curl -sL https://api.openai.com/v1/completions -H "Content-Type: application/json" -H "Authorization: Bearer %s" -d '%s']]


    local command = string.format(command_template, os.getenv("OPENAI_TOKEN"), bodyStr)
    return curlOpenAI(command)
end

M.getEdit = function(text, prompt)
    
    local body = {
        model="text-davinci-edit-001",
        input=text,
        instruction=prompt,
        temperature=0.1,
    }
    local bodyStr = vim.json.encode(body)

    local command_template = [[curl -sL https://api.openai.com/v1/edits -H "Content-Type: application/json" -H "Authorization: Bearer %s" -d '%s']]


    local command = string.format(command_template, os.getenv("OPENAI_TOKEN"), bodyStr)
    return curlOpenAI(command)
    end


M.writeToBuffer = function(text)
    -- Get the current buffer handle
    local buf = vim.api.nvim_get_current_buf()

    -- Get the current position of the cursor
    local pos = vim.api.nvim_win_get_cursor(0)

    lines = vim.split(text, "\n")
    -- Set the string to append to the buffer

    -- Append the string to the buffer at the current position of the cursor
    vim.api.nvim_put(lines, "c", false, true)
end

function P(x) 
    print(vim.inspect(x))
end

M.replaceSelection = function (args)
    local buf = vim.api.nvim_get_current_buf()
    local start = vim.api.nvim_buf_get_mark(buf, "<")
    local stop =  vim.api.nvim_buf_get_mark(buf, ">")

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

    resLines = vim.split(result, "\n")
    vim.api.nvim_buf_set_text(
        buf,
        start[1]-1,
        start[2],
        stop[1]-1,
        stop[2],
        resLines
    )
end

M.generate = function(args)
    local prompt = args.args
    local resp = M.getCompletion(prompt)
    M.writeToBuffer(resp)
end

M.sendLines = function()
    local text = M.getLines()
    local resp = M.getCompletion(text)
    M.writeToBuffer(resp)
end

return M
