# gpt.nvim

> Very much a work in progress still.

## Installation

```
" Using vim-plug:
Plug 'juliusolson/gpt.nvim'
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

1. Run `:GPT`
2. All text in the buffer up until the current cursor position is sent to the model and is used to generate a completion.
3. The completion is inserted at the cursors current location
