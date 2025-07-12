local M = {}

local config = require('jsonvalid8.config')
local utils = require('jsonvalid8.utils')

local current_schema_buf = nil
local current_json_buf = nil
local current_divider_buf = nil
local last_left_win = nil

-- Helper: Find the most recent JSON buffer, prioritizing the current buffer
local function find_json_buffer()
  local cur_buf = vim.api.nvim_get_current_buf()
  if vim.api.nvim_buf_get_option(cur_buf, 'filetype') == 'json' then
    local lines = vim.api.nvim_buf_get_lines(cur_buf, 0, -1, false)
    if #lines > 0 and not (#lines == 1 and lines[1] == "") then
      return cur_buf
    end
  end
  -- Fallback: search all loaded buffers
  local bufs = vim.api.nvim_list_bufs()
  for _, buf in ipairs(bufs) do
    if buf ~= cur_buf and vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_option(buf, 'filetype') == 'json' then
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      if #lines > 0 and not (#lines == 1 and lines[1] == "") then
        return buf
      end
    end
  end
  return nil
end

--- Opens the floating window for schema editing and validation, with a right split showing the JSON and a visible divider.
function M.open()
  local opts = config.get()
  local width = opts.window.width
  local height = opts.window.height
  local divider_width = 2
  local split_ratio = 0.5 -- 50% left, 50% right (excluding divider)
  local left_width = math.floor((width - divider_width) * split_ratio)
  local right_width = width - divider_width - left_width

  -- Calculate window position (center of screen)
  local win_width = vim.api.nvim_win_get_width(0)
  local win_height = vim.api.nvim_win_get_height(0)
  local row = math.floor((win_height - height) / 2)
  local col = math.floor((win_width - width) / 2)

  -- Create parent floating window (non-focusable, non-editable)
  local parent_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(parent_buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_lines(parent_buf, 0, -1, false, {' '})
  vim.api.nvim_buf_set_option(parent_buf, 'modifiable', false)
  local parent_win = vim.api.nvim_open_win(parent_buf, false, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = opts.window.border,
    title = opts.window.title,
    title_pos = 'center',
    focusable = false,
  })
  vim.api.nvim_win_set_option(parent_win, 'wrap', false)
  vim.api.nvim_win_set_option(parent_win, 'number', false)

  -- Create schema buffer (left split)
  local schema_buf = vim.api.nvim_create_buf(false, true)
  current_schema_buf = schema_buf
  vim.api.nvim_buf_set_option(schema_buf, 'modifiable', true)
  vim.api.nvim_buf_set_option(schema_buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(schema_buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(schema_buf, 'filetype', 'jsonvalid8')
  local schema_lines = {
    "# jsonvalid8.nvim - Schema Definition",
    "# Press ? for help, Ctrl+s to validate, Ctrl+p for preview",
    "",
    "# Example schema:",
    "name: string",
    "age: integer(minimum=0, maximum=120)",
    "email: string(format=email)",
    "tags: array[string]",
    "profile: object{",
    "  bio?: string",
    "  active: boolean = true",
    "}",
    "",
  }
  vim.api.nvim_buf_set_lines(schema_buf, 0, -1, false, schema_lines)
  vim.api.nvim_buf_set_name(schema_buf, 'jsonvalid8://schema_' .. os.time())

  -- Create divider buffer (center)
  local divider_buf = vim.api.nvim_create_buf(false, true)
  current_divider_buf = divider_buf
  local divider_lines = {}
  for _ = 1, height do
    table.insert(divider_lines, '│')
  end
  vim.api.nvim_buf_set_lines(divider_buf, 0, -1, false, divider_lines)
  vim.api.nvim_buf_set_option(divider_buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(divider_buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(divider_buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(divider_buf, 'filetype', 'jsonvalid8_divider')

  -- Find the JSON buffer (current buffer preferred)
  local json_buf_src = find_json_buffer()
  local json_lines
  if json_buf_src then
    json_lines = vim.api.nvim_buf_get_lines(json_buf_src, 0, -1, false)
  else
    json_lines = {"# No JSON file open in any buffer"}
  end

  -- Create JSON buffer (right split, read-only)
  local json_buf = vim.api.nvim_create_buf(false, true)
  current_json_buf = json_buf
  vim.api.nvim_buf_set_option(json_buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(json_buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(json_buf, 'filetype', 'json')
  vim.api.nvim_buf_set_lines(json_buf, 0, -1, false, json_lines)
  vim.api.nvim_buf_set_option(json_buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(json_buf, 'readonly', true)
  vim.api.nvim_buf_set_name(json_buf, 'jsonvalid8://json_' .. os.time())

  -- Create left, divider, and right windows inside the parent floating window
  local left_win = vim.api.nvim_open_win(schema_buf, true, {
    relative = 'win',
    win = parent_win,
    width = left_width,
    height = height,
    row = 0,
    col = 0,
    focusable = true,
    style = 'minimal',
    border = 'none',
  })
  local divider_win = vim.api.nvim_open_win(divider_buf, false, {
    relative = 'win',
    win = parent_win,
    width = divider_width,
    height = height,
    row = 0,
    col = left_width,
    focusable = false,
    style = 'minimal',
    border = 'none',
  })
  local right_win = vim.api.nvim_open_win(json_buf, false, {
    relative = 'win',
    win = parent_win,
    width = right_width,
    height = height,
    row = 0,
    col = left_width + divider_width,
    focusable = false,
    style = 'minimal',
    border = 'none',
  })
  vim.api.nvim_win_set_option(left_win, 'wrap', true)
  vim.api.nvim_win_set_option(left_win, 'number', opts.ui.show_line_numbers)
  vim.api.nvim_win_set_option(right_win, 'wrap', true)
  vim.api.nvim_win_set_option(right_win, 'number', opts.ui.show_line_numbers)
  vim.api.nvim_win_set_option(divider_win, 'wrap', false)
  vim.api.nvim_win_set_option(divider_win, 'number', false)

  -- Focus management: if parent or right_win is focused, immediately return to left_win
  local function refocus_left()
    if vim.api.nvim_win_is_valid(left_win) then
      vim.api.nvim_set_current_win(left_win)
    end
  end
  vim.api.nvim_create_autocmd('WinEnter', {
    callback = function()
      local curwin = vim.api.nvim_get_current_win()
      if curwin == right_win or curwin == parent_win then
        vim.defer_fn(refocus_left, 10)
      end
    end,
    desc = 'jsonvalid8: prevent focus on parent/right',
  })

  last_left_win = left_win

  -- Set up keybindings for the schema (left) window
  M.setup_keybindings(parent_win, left_win, schema_buf, json_buf, {parent_win, left_win, divider_win, right_win, schema_buf, divider_buf, json_buf})
  vim.api.nvim_set_current_win(left_win)
  vim.api.nvim_win_set_cursor(left_win, {4, 0})
  utils.notify("jsonvalid8.nvim opened! Press ? for help.", vim.log.levels.INFO)
end

--- Set up keybindings for the floating window
function M.setup_keybindings(parent_win, left_win, schema_buf, json_buf, handles)
  local keymaps = {
    ['<C-s>'] = function() require('jsonvalid8.validator').validate(schema_buf, json_buf) end,
    ['<C-p>'] = function() M.show_preview() end,
    ['?'] = function() M.show_help() end,
    ['q'] = function() M.close_window(handles) end,
    ['<Esc>'] = function() M.close_window(handles) end,
  }
  for key, func in pairs(keymaps) do
    vim.keymap.set('n', key, func, { buffer = schema_buf, noremap = true, silent = true })
  end
end

--- Close the floating window and clean up
function M.close_window(handles)
  local parent_win, left_win, divider_win, right_win, schema_buf, divider_buf, json_buf = unpack(handles)
  for _, win in ipairs({left_win, divider_win, right_win, parent_win}) do
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  for _, buf in ipairs({schema_buf, divider_buf, json_buf}) do
    if buf and vim.api.nvim_buf_is_valid(buf) then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name:match("jsonvalid8://") or buf_name == "" then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
  end
  current_schema_buf = nil
  current_json_buf = nil
  current_divider_buf = nil
end

--- Clears validation diagnostics and virtual text.
function M.clear()
  vim.diagnostic.reset()
  utils.notify("Validation results cleared.", vim.log.levels.INFO)
end

--- Shows help popup with syntax examples.
function M.show_help()
  local help_text = {
    "jsonvalid8.nvim - Schema Syntax Help",
    "",
    "Basic Types:",
    "  name: string",
    "  age: integer",
    "  price: number",
    "  is_active: boolean",
    "",
    "Constraints:",
    "  age: integer(minimum=0, maximum=120)",
    "  email: string(format=email)",
    "  password: string(minLength=8, maxLength=64)",
    "",
    "Arrays:",
    "  tags: array[string]",
    "  numbers: array[integer]",
    "",
    "Objects:",
    "  profile: object{",
    "    bio: string",
    "    active: boolean",
    "  }",
    "",
    "Optional Fields:",
    "  description?: string",
    "  tags: array[string] = []",
    "  is_active: boolean = true",
    "",
    "Press q to close this help",
  }
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, help_text)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  local max_width = 0
  for _, line in ipairs(help_text) do
    max_width = math.max(max_width, #line)
  end
  local width = math.min(max_width + 4, 80)
  local height = math.min(#help_text + 4, 30)
  local win_width = vim.api.nvim_win_get_width(0)
  local win_height = vim.api.nvim_win_get_height(0)
  local row = math.floor((win_height - height) / 2)
  local col = math.floor((win_width - width) / 2)
  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = 'jsonvalid8.nvim - Help',
    title_pos = 'center',
  }
  local win = vim.api.nvim_open_win(buf, true, win_opts)
  vim.keymap.set('n', 'q', function() vim.api.nvim_win_close(win, true) end, { buffer = buf, noremap = true, silent = true })
  vim.keymap.set('n', '<Esc>', function() vim.api.nvim_win_close(win, true) end, { buffer = buf, noremap = true, silent = true })
end

--- Shows schema preview in split view.
function M.show_preview()
  utils.notify("Schema preview not yet implemented.", vim.log.levels.WARN)
end

return M
