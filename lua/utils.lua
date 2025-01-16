local utils = {}

utils.concat_tables = function(...)
    local result = {}
    local pos = 1

    for _, tbl in ipairs({ ... }) do
        table.move(tbl, 1, #tbl, pos, result)
        pos = pos + #tbl
    end

    return result
end

utils.append_data_to_buf = function(data, buf)
    local lc = vim.api.nvim_buf_line_count(buf)
    local l = vim.api.nvim_buf_get_lines(buf, lc - 1, lc, true)
    vim.api.nvim_buf_set_text(buf, lc - 1, #l[1], -1, -1, vim.split(data or "\n", "\n"))
end

return utils
