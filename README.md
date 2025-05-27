# line-numbers.nvim

A Neovim plugin to display both relative and absolute line numbers side-by-side using the `statuscolumn` feature (requires Neovim 0.9+).

## ✨ Features

- Show relative, absolute, both, or no line numbers
- Configurable format (`abs_rel` or `rel_abs`)
- Custom separator between numbers
- Highlight groups for styling relative and absolute numbers
- Current line highlighting for styling the numbers on the cursor line
- Lightweight and Lua-only

![screenshot](https://github.com/user-attachments/assets/ca8dc59b-7ad1-40c4-8a38-09bec8e0c707)

## ⚡️ Requirements

- Neovim >= 0.9.0
- [lazy.nvim](https://github.com/folke/lazy.nvim) plugin manager
  - **OR** a plugin manager that uses **Neovim**'s native package system

## 📦 Installation

### With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "shrynx/line-numbers.nvim",
  opts = {},
}
```

### With [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use({
  "shrynx/line-numbers.nvim",
  config = function()
    require("line-numbers").setup({})
  end
})
```

## ⚙️ Options

All the options are optional and below are the defaults.

```lua
{
  mode = "both",      -- "relative", "absolute", "both", "none"
  format = "abs_rel", -- or "rel_abs"
  separator = " ",
  rel_highlight = { link = "LineNr" },
  abs_highlight = { link = "LineNr" },
  current_rel_highlight = { link = "CursorLineNr" },
  current_abs_highlight = { link = "CursorLineNr" },
}
```

## 🔀 Commands

- :LineNumberToggle
- :LineNumberRelative
- :LineNumberAbsolute
- :LineNumberBoth
- :LineNumberNone

## 📚 Help

After installation, run:

```vim
:helptags ~/.local/share/nvim/lazy/line-numbers.nvim/doc
```

```vim
:help line-numbers
```
