vim.api.nvim_create_user_command('GPTCOMP', function(params)
    require('gpt').sendLines()
end, { })

vim.api.nvim_create_user_command('GPTEDIT', function(params)
    require('gpt').replaceSelection(params)
end, { range=true, nargs="*" })


vim.api.nvim_create_user_command('GPTGEN', function(params)
    require('gpt').generate(params)
end, { range=true, nargs="*" })

