# gpt.nvim

> work in progress

## Installation

External dependencies: `curl`

```lua
{
    "juliusolson/gpt.nvim",
    config = function()
        local gpt = require("gpt")
        gpt.setup()
        vim.keymap.set("n", "<leader>ai", function() gpt.open() end, {})
    end
}
```

You also need to have an OpenAI API key accessible as an env variable
```bash
# .bashrc/.bash_profile
export OPENAI_API_KEY="<your-key>"
```

## Usage

* Write your prompt in the prompt window, enter normal mode and hit enter to send the prompt
* The answer will be streamed into the output window
* Close by hittin `q` in normal mode in the prompt window
