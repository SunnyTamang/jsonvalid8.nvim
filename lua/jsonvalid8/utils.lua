local M = {}

function M.notify(msg, level, opts)
  vim.notify(msg, level or vim.log.levels.INFO, opts or { title = 'jsonvalid8.nvim' })
end

function M.split(str, sep)
  local t = {}
  for s in string.gmatch(str, "([^" .. sep .. "]+)") do
    table.insert(t, s)
  end
  return t
end

return M
