if vim.fn.has('nvim-0.7') == 0 then
  vim.api.nvim_err_writeln('jsonvalid8.nvim requires Neovim 0.7 or higher')
  return
end

local jsonvalid8 = require('jsonvalid8')

vim.api.nvim_create_user_command('JsonValid8Open', function()
  jsonvalid8.open()
end, {})

vim.api.nvim_create_user_command('JsonValid8Validate', function()
  jsonvalid8.validate()
end, {})

vim.api.nvim_create_user_command('JsonValid8Clear', function()
  jsonvalid8.clear()
end, {})

vim.api.nvim_create_user_command('JsonValid8Templates', function()
  jsonvalid8.templates()
end, {})

vim.api.nvim_create_user_command('JsonValid8Export', function()
  jsonvalid8.export()
end, {})

-- Default keybindings (can be overridden in setup)
vim.keymap.set('n', '<leader>jv', function() jsonvalid8.open() end, { desc = 'Open jsonvalid8 validator' })
vim.keymap.set('n', '<leader>jt', function() jsonvalid8.templates() end, { desc = 'Show jsonvalid8 templates' })
vim.keymap.set('n', '<leader>jc', function() jsonvalid8.clear() end, { desc = 'Clear jsonvalid8 validation results' })
