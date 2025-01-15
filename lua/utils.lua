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

return utils
