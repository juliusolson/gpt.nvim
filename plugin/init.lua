vim.api.nvim_create_user_command('GPTCOMP', function(params)
    require('gpt').complete()
end, { })

vim.api.nvim_create_user_command('GPTEDIT', function(params)
    require('gpt').editSelection(params)
end, { range=true, nargs="*" })


vim.api.nvim_create_user_command('GPTGEN', function(params)
    require('gpt').generateFromPrompt(params)
end, { range=true, nargs="*" })

