# gpt.nvim

> work in progress


## What

* Lightweight, repsonsive AI chat plugin that streams AI output to a buffer
* Supports various models and layouts
    * Model can be changed mid conversation
* Easily include content from clipboard register using command `/paste` in prompt

## Why

* Less complexity than other AI plugins for Neovim. No completion - just a chat interface
* Fun way to learn writing plugins

## Installation

Dependencies: `curl`, `plenary.nvim`

```lua
{
    "juliusolson/gpt.nvim",
    config = function()
        local gpt = require("gpt")
        gpt.setup({ model = "gpt-4o-mini", layout = "float" })

        vim.keymap.set("n", "<leader>ai", gpt.open, { silent = true })
    end,
    dependencies = {
        "nvim-lua/plenary.nvim"
    },
}
```

You also need to have an OpenAI API key accessible as an env variable
```bash
# .bashrc/.bash_profile
export OPENAI_API_KEY="<your-key>"
```

## Config

Option          |  default                                   |  constraints
----            | ---------                                  | ------
`model`         | `gpt-4o-mini`                              | any open ai model
`output_width`  | 100                                        | `int` (only for split view) 
`prompt_height` | 5                                          | `int` (only for split view)
`base_url`      | https://api.openai.com/v1/chat/completions |  
`layout`        | split                                      | `{split, float, fullscreen}`
`system_prompt` | n/a                                        |


## Usage

* Write your prompt in the prompt window, enter normal mode and hit enter to send the prompt
* The answer will be streamed into the output window

### Keymaps

* Choose model: `M` in normal mode in prompt window
* Select layout: `L` in normal mode in prompt/output window
* Close `q` in normal mode in prompt/output window
* Open / Go to interface `<leader> ai` (set through plugin conf)

## Features

* Toggle chat with persistant state
* Layout options `{split, float}`
* Model switching on the fly
* Add whatever is in the clipboard register (`'` register) by using command `/paste` in the prompt
    * The content from the register will replace the command in the prompt text

## TODO

* [ ] Handle api errors
* [ ] Handle closing of buffer / window mid-stream
* [ ] Support other apis
* [ ] More customizable / extensible
    * [x] layouts
    * [ ] keymaps
    * [ ] commands
* [ ] Save conversation to file
* [ ] Reset conversation/context
* [ ] Remove last message from context

