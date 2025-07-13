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

--- Pretty-print a Lua table as indented JSON
function M.pretty_json(tbl, indent)
  indent = indent or 2
  local ok, json = pcall(vim.fn.json_encode, tbl)
  if not ok or not json then return '{}' end
  local function indent_json(str, level)
    local res, lev = {}, 0
    for line in str:gmatch('[^\n]+') do
      if line:find('^[%]}]') then lev = lev - 1 end
      table.insert(res, string.rep(' ', lev * indent) .. line)
      if line:find('[%[{]$') then lev = lev + 1 end
    end
    return table.concat(res, '\n')
  end
  -- Use vim.fn.json_decode/encode to get newlines, then indent
  local lines = {}
  for line in json:gsub('{', '{\n'):gsub('}', '\n}'):gsub(',', ',\n'):gmatch('[^\n]+') do
    table.insert(lines, line)
  end
  return indent_json(table.concat(lines, '\n'), 0)
end

return M
