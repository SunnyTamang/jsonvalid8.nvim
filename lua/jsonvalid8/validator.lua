local M = {}

local utils = require('jsonvalid8.utils')
local config = require('jsonvalid8.config')
local parser = require('jsonvalid8.parser')

local ns = vim.api.nvim_create_namespace("jsonvalid8.nvim")

--- Find the line number in the JSON buffer for a given field (dot notation supported)
local function find_field_line(json_lines, field)
  local pattern = '"' .. field:gsub('%.', '"%s*:%s*{.-"') .. '"%s*:'
  for i, line in ipairs(json_lines) do
    if line:match(pattern) then
      return i
    end
  end
  -- Fallback: try just the last part of the field
  local last = field:match("([^.]+)$")
  if last then
    for i, line in ipairs(json_lines) do
      if line:match('"' .. last .. '"%s*:') then
        return i
      end
    end
  end
  return 1
end

--- Validates the JSON buffer against the schema buffer
function M.validate(schema_buf, json_buf)
  if not schema_buf or not json_buf then
    utils.notify("Could not find schema or JSON buffer for validation.", vim.log.levels.ERROR)
    return
  end

  -- Get the schema content from the schema buffer
  local schema_lines = vim.api.nvim_buf_get_lines(schema_buf, 0, -1, false)
  -- Filter out comments and empty lines
  local clean_schema = {}
  for _, line in ipairs(schema_lines) do
    local trimmed = line:match("^%s*(.-)%s*$")
    if trimmed ~= "" and not trimmed:match("^#") then
      table.insert(clean_schema, trimmed)
    end
  end
  if #clean_schema == 0 then
    utils.notify("No schema definition found. Please define a schema first.", vim.log.levels.ERROR)
    return
  end
  -- Parse the schema
  local json_schema, parse_error = parser.parse(clean_schema)
  if parse_error then
    utils.notify("Schema parsing error: " .. parse_error, vim.log.levels.ERROR)
    return
  end

  -- Get the JSON content from the JSON buffer
  local json_lines = vim.api.nvim_buf_get_lines(json_buf, 0, -1, false)
  local json_content = table.concat(json_lines, "\n")
  -- Try to parse the JSON
  local ok, json_data = pcall(vim.fn.json_decode, json_content)
  if not ok or not json_data then
    utils.notify("Invalid JSON in right split: " .. (json_data or "(decode error)"), vim.log.levels.ERROR)
    return
  end

  -- For now, do a basic validation
  local validation_result = M.basic_validate(json_data, json_schema)
  if validation_result.valid then
    utils.notify("✓ Validation successful! All fields are valid.", vim.log.levels.INFO)
    vim.diagnostic.reset(ns, json_buf)
  else
    -- Show all error messages in a notification
    local msg = "✗ Validation failed:\n"
    for _, err in ipairs(validation_result.errors or {}) do
      msg = msg .. string.format("- %s: %s\n", err.field or "?", err.message)
    end
    utils.notify(msg, vim.log.levels.ERROR)
    M.show_diagnostics(validation_result.errors, json_buf, json_lines)
  end
end

--- Basic validation function (placeholder for now)
function M.basic_validate(data, schema)
  -- This is a simplified validation for demonstration
  -- In a real implementation, you would use a proper JSON Schema validator
  
  if type(data) ~= "table" then
    return { valid = false, error = "Data must be an object" }
  end
  
  local errors = {}
  
  -- Check required fields
  if schema.required then
    for _, field in ipairs(schema.required) do
      if data[field] == nil then
        table.insert(errors, {
          field = field,
          message = "Required field '" .. field .. "' is missing",
          line = 1,
          col = 1
        })
      end
    end
  end
  
  -- Check field types (simplified)
  if schema.properties then
    for field, field_schema in pairs(schema.properties) do
      if data[field] ~= nil then
        local field_type = field_schema.type
        local actual_type = type(data[field])
        
        if field_type == "string" and actual_type ~= "string" then
          table.insert(errors, {
            field = field,
            message = "Field '" .. field .. "' must be a string, got " .. actual_type,
            line = 1,
            col = 1
          })
        elseif field_type == "integer" and actual_type ~= "number" then
          table.insert(errors, {
            field = field,
            message = "Field '" .. field .. "' must be an integer, got " .. actual_type,
            line = 1,
            col = 1
          })
        elseif field_type == "boolean" and actual_type ~= "boolean" then
          table.insert(errors, {
            field = field,
            message = "Field '" .. field .. "' must be a boolean, got " .. actual_type,
            line = 1,
            col = 1
          })
        elseif field_type == "array" and actual_type ~= "table" then
          table.insert(errors, {
            field = field,
            message = "Field '" .. field .. "' must be an array, got " .. actual_type,
            line = 1,
            col = 1
          })
        end
      end
    end
  end
  
  if #errors > 0 then
    return { valid = false, error = #errors .. " validation error(s)", errors = errors }
  else
    return { valid = true }
  end
end

--- Show diagnostics for validation errors
function M.show_diagnostics(errors, buf, json_lines)
  local diagnostics = {}
  for _, error in ipairs(errors) do
    local lnum = 1
    if error.field and json_lines then
      lnum = find_field_line(json_lines, error.field)
    end
    table.insert(diagnostics, {
      lnum = lnum - 1, -- Convert to 0-based
      col = 0,
      severity = vim.diagnostic.severity.ERROR,
      message = error.message,
      source = "jsonvalid8.nvim"
    })
  end
  vim.diagnostic.set(ns, buf, diagnostics)
end

return M
