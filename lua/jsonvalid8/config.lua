local M = {}

local default_config = {
  keybinding = "<leader>jv",
  window = {
    width = 110,
    height = 32,
    border = "rounded",
    title = "jsonvalid8.nvim",
  },
  validator = {
    engine = "lua", -- "lua", "node", or "python"
    auto_validate = false,
    show_success_notification = true,
    virtual_text = true,
  },
  schemas = {
    save_location = vim.fn.stdpath('data') .. '/jsonvalid8/schemas',
    auto_save = true,
    templates = true,
  },
  ui = {
    syntax_highlighting = true,
    show_line_numbers = true,
    show_preview = true,
  },
}

M.options = vim.deepcopy(default_config)

function M.setup(user_config)
  if user_config then
    M.options = vim.tbl_deep_extend('force', {}, default_config, user_config)
  end
end

function M.get()
  return M.options
end

return M
