# jsonvalid8.nvim

A modern, user-friendly JSON Schema validator plugin for Neovim. Define schemas with intuitive syntax, validate JSON files on-the-fly, and get actionable feedback—all from a beautiful floating window UI.

## Features
- Simplified schema syntax (auto-converts to JSON Schema)
- Floating window UI with syntax highlighting
- Real-time JSON validation with diagnostics
- Schema templates and library
- Virtual text and Neovim diagnostics integration
- Extensible, modular Lua codebase

## Installation

**With [lazy.nvim](https://github.com/folke/lazy.nvim):**
```lua
{
  'yourname/jsonvalid8.nvim',
  config = function()
    require('jsonvalid8').setup()
  end
}
```

## Usage
1. Open a JSON file in Neovim.
2. Press `<leader>jv` or run `:JsonValid8Open` to open the validator.
3. Define your schema in the floating window using the intuitive syntax.
4. Press `<C-s>` to validate, `<C-p>` to preview JSON Schema, or `?` for help.
5. See validation results inline and in diagnostics.

## Example Schema
```
name: string
age: integer(minimum=0, maximum=120)
email: string(format=email)
tags: array[string]
profile: object{
  bio?: string
  active: boolean = true
}
```

## Commands
- `:JsonValid8Open`      Open schema validator
- `:JsonValid8Validate`  Validate current JSON file
- `:JsonValid8Clear`     Clear validation results
- `:JsonValid8Templates` Show schema templates
- `:JsonValid8Export`    Export schema as JSON Schema file

## Configuration
```lua
require("jsonvalid8").setup({
  -- See :help jsonvalid8.nvim for all options
})
```

## Documentation
See `:help jsonvalid8.nvim` or [doc/jsonvalid8.txt](doc/jsonvalid8.txt) for full details.
