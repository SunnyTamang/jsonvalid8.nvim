# jsonvalid8.nvim

A modern, user-friendly JSON Schema validator plugin for Neovim. Validate JSON files on-the-fly, get actionable feedback, and enjoy a beautiful floating window UI.

**Repo:** [@https://github.com/SunnyTamang/jsonvalid8.nvim](https://github.com/SunnyTamang/jsonvalid8.nvim)

---

## Features
- Validate JSON files using industry-standard JSON Schema
- Floating window UI with schema editor and JSON preview
- Inline diagnostics and error messages
- Pretty-printed schema preview
- Python-powered validation (using `jsonschema`)
- Minimal schema skeleton and README example for quick start

---
## Requirements
- **Neovim 0.7+**
- **Python 3** (for validation)
- **Python jsonschema library**
  ```sh
  pip install jsonschema
  ```

---

## Installation

**With [lazy.nvim](https://github.com/folke/lazy.nvim):**
```lua
{
  'SunnyTamang/jsonvalid8.nvim',
  config = function()
    require('jsonvalid8').setup()
  end
}
```

---

## Demo

---

## Usage

1. Open a JSON file in Neovim.
2. Press `<leader>jv` or run `:JsonValid8Open` to open the validator.
3. Paste or edit your JSON Schema in the left split. The right split shows your JSON file.
4. Press `<C-s>` to validate, `<C-p>` to preview the schema, or `?` for help.
5. See validation results inline and in diagnostics.

---

## Example JSON Schema

Below is an example schema for a product catalog entry:

```json
{
  "type": "object",
  "properties": {
    "id": { "type": "integer" },
    "name": { "type": "string" },
    "category": { "type": "string" },
    "price": { "type": "number" },
    "in_stock": { "type": "boolean" },
    "tags": { "type": "array", "items": { "type": "string" } },
    "specs": {
      "type": "object",
      "properties": {
        "color": { "type": "string" },
        "weight_grams": { "type": "integer" },
        "battery_life_hours": { "type": "integer" }
      },
      "required": ["color", "weight_grams", "battery_life_hours"]
    },
    "ratings": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "user": { "type": "string" },
          "score": { "type": "integer" },
          "comment": { "type": "string" }
        },
        "required": ["user", "score", "comment"]
      }
    },
    "release_date": { "type": "string", "format": "date" }
  },
  "required": ["id", "name", "category", "price", "in_stock", "tags", "specs", "ratings", "release_date"]
}
```

---

## Minimal Schema Skeleton

Start with this and add your fields:

```json
{
  "type": "object",
  "properties": {
    
  },
  "required": []
}
```

---

## Commands
- `:JsonValid8Open`      Open schema validator
- `:JsonValid8Validate`  Validate current JSON file
- `:JsonValid8Clear`     Clear validation results
- `:JsonValid8Templates` Show schema templates (future planning)
- `:JsonValid8Export`    Export schema as JSON Schema file

---

## Keybindings (in schema editor)
- `<C-s>`   Validate JSON file
- `<C-p>`   Preview JSON Schema
- `?`       Show help
- `q`, `<Esc>` Close the floating window

---

## Help & Tips
- The schema editor uses standard [JSON Schema](https://json-schema.org/).
- For a full example, see above or the README in the repo.
- To define an object property:
  ```json
  "profile": { "type": "object", "properties": { ... }, "required": [ ... ] }
  ```
- To define an array of strings:
  ```json
  "tags": { "type": "array", "items": { "type": "string" } }
  ```
- To require a property, add its name to the `"required"` array.
- To specify a type:
  ```json
  "name": { "type": "string" }, "age": { "type": "integer" }
  ```
- To add constraints:
  ```json
  "age": { "type": "integer", "minimum": 0, "maximum": 120 }
  ```
- To allow only certain values:
  ```json
  "status": { "type": "string", "enum": ["active", "inactive"] }
  ```

---

## Troubleshooting
- If you see errors about invalid schema or data, check your JSON and schema formatting.
- Make sure Python 3 and the `jsonschema` library are installed.
- For more help, see the help popup (`?`) or the [repo](https://github.com/SunnyTamang/jsonvalid8.nvim).

---

## Contributing
Pull requests and issues are welcome! See the repo for details.

---

## License
MIT

## Note on Schema Templates
- Schema templates may be added in future updates to make it even easier to get started with common schema patterns.
