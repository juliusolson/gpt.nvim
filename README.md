# gpt.nvim

> Very much a work in progress still.

## Installation

External dependencies: `curl`

```vim
" Using vim-plug:
Plug 'juliusolson/gpt.nvim'
```



```lua
-- using lazy
require("lazy").setup({
    "juliusolson/gpt.nvim"
})

```

You also need to have an OpenAI API key accessible as an env variable
```bash
# .bashrc/.bash_profile
export OPENAI_API_KEY="<your-key>"
```

## Usage

### Edit selected text

1. Highlight text in visual mode
2. Run `:GPTEDIT <instruction>`
3. The edited text replaces the highlighted text

### Generate text

1. Run `:GPTGEN <prompt-here>`
2. The generated text is inserted at the cursors current location


### Completion

1. Run `:GPTCOMP`
2. All text in the buffer up until the current cursor position is sent to the model and is used to generate a completion.
3. The completion is inserted at the cursors current location
