local M = {}

local utils = require('jsonvalid8.utils')
local config = require('jsonvalid8.config')
--local parser = require('jsonvalid8.parser') -- [universal schema: commented out]

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
  -- Parse the schema as JSON
  local schema_content = table.concat(clean_schema, "\n")

  -- Get the JSON content from the JSON buffer
  local json_lines = vim.api.nvim_buf_get_lines(json_buf, 0, -1, false)
  local json_content = table.concat(json_lines, "\n")

  -- Write schema and data to temp files
  local tmp_schema = os.tmpname() .. ".json"
  local tmp_data = os.tmpname() .. ".json"
  local sf = io.open(tmp_schema, "w")
  if not sf then utils.notify("Failed to write temp schema file", vim.log.levels.ERROR) return end
  sf:write(schema_content) sf:close()
  local df = io.open(tmp_data, "w")
  if not df then utils.notify("Failed to write temp data file", vim.log.levels.ERROR) return end
  df:write(json_content) df:close()

  -- Call the Python validator
  local cmd = string.format('python3 "%s/validate_jsonschema.py" "%s" "%s"', vim.fn.getcwd(), tmp_schema, tmp_data)
  local result = vim.fn.system(cmd)
  os.remove(tmp_schema)
  os.remove(tmp_data)

  local ok, parsed = pcall(vim.fn.json_decode, result)
  if not ok or not parsed then
    utils.notify("Validation error: " .. (result or "(decode error)"), vim.log.levels.ERROR)
    return
  end
  if parsed.error then
    utils.notify("Schema validation error: " .. parsed.error, vim.log.levels.ERROR)
    return
  end
  if parsed.valid then
    utils.notify("✓ Validation successful! All fields are valid.", vim.log.levels.INFO)
    vim.diagnostic.reset(ns, json_buf)
  else
    local msg = "✗ Validation failed:\n"
    local diagnostics = {}
    if parsed.errors then
      for _, err in ipairs(parsed.errors) do
        msg = msg .. "- " .. (table.concat(err.path, ".") or "?") .. ": " .. err.message .. "\n"
        -- Find line number for the error path
        local lnum = 1
        if err.path and #err.path > 0 then
          local field = err.path[1]
          for i, line in ipairs(json_lines) do
            if line:match('"' .. field .. '"%s*:') then
              lnum = i
              break
            end
          end
        end
        table.insert(diagnostics, {
          lnum = lnum - 1, -- 0-based
          col = 0,
          severity = vim.diagnostic.severity.ERROR,
          message = err.message,
          source = "jsonvalid8.nvim"
        })
      end
      vim.diagnostic.set(ns, json_buf, diagnostics)
    else
      msg = msg .. (parsed.message or "Unknown error")
    end
    utils.notify(msg, vim.log.levels.ERROR)
  end
end

--- Basic validation function (placeholder for now)
function M.basic_validate(data, schema, path)
  path = path or ""
  if type(data) ~= "table" then
    return { valid = false, error = "Data must be an object" }
  end
  local errors = {}
  -- Check required fields
  if schema.required then
    for _, field in ipairs(schema.required) do
      if data[field] == nil and not (schema.properties and schema.properties[field] and schema.properties[field].default ~= nil) then
        table.insert(errors, {
          field = (path ~= "" and path .. "." or "") .. field,
          message = "Required field '" .. field .. "' is missing",
          line = 1,
          col = 1
        })
      end
    end
  end
  -- Check field types and constraints
  if schema.properties then
    for field, field_schema in pairs(schema.properties) do
      local full_path = (path ~= "" and path .. "." or "") .. field
      local value
      local used_default = false
      if data[field] ~= nil then
        value = data[field]
      elseif field_schema.default ~= nil then
        value = field_schema.default
        used_default = true
      end
      if value ~= nil then
        local field_type = field_schema.type
        local actual_type = type(value)
        local type_mismatch = false
        if field_type == "string" then
          type_mismatch = actual_type ~= "string"
        elseif field_type == "integer" then
          type_mismatch = actual_type ~= "number" or math.floor(value) ~= value
        elseif field_type == "number" then
          type_mismatch = actual_type ~= "number"
        elseif field_type == "boolean" then
          type_mismatch = actual_type ~= "boolean"
        elseif field_type == "array" then
          type_mismatch = actual_type ~= "table"
          -- Recursively check array items
          if not type_mismatch and field_schema.items then
            for i, item in ipairs(value) do
              local arr_result = M.basic_validate({item = item}, {properties = {item = field_schema.items}}, full_path .. "[" .. i .. "]")
              if arr_result.errors and #arr_result.errors > 0 then
                for _, e in ipairs(arr_result.errors) do table.insert(errors, e) end
              end
            end
          end
        elseif field_type == "object" then
          type_mismatch = actual_type ~= "table"
          -- Recursively check object properties
          if not type_mismatch then
            local obj_result = M.basic_validate(value, field_schema, full_path)
            if obj_result.errors and #obj_result.errors > 0 then
              for _, e in ipairs(obj_result.errors) do table.insert(errors, e) end
            end
          end
        end
        if type_mismatch then
          table.insert(errors, {
            field = full_path,
            message = "Field '" .. full_path .. "' must be a " .. field_type .. ", got " .. actual_type .. (used_default and " (default used)" or ""),
            line = 1,
            col = 1
          })
        else
          -- Only check constraints if the value is present (from JSON or default)
          if field_type == "string" then
            if field_schema.minLength and #value < field_schema.minLength then
              table.insert(errors, { field = full_path, message = "Field '" .. full_path .. "' is shorter than minLength " .. field_schema.minLength, line = 1, col = 1 })
            end
            if field_schema.maxLength and #value > field_schema.maxLength then
              table.insert(errors, { field = full_path, message = "Field '" .. full_path .. "' is longer than maxLength " .. field_schema.maxLength, line = 1, col = 1 })
            end
            if field_schema.pattern then
              local pat = field_schema.pattern:gsub('^%^(.*)%$$', '%1')
              if not tostring(value):match(pat) then
                table.insert(errors, { field = full_path, message = "Field '" .. full_path .. "' does not match pattern " .. field_schema.pattern, line = 1, col = 1 })
              end
            end
            if field_schema.format == "email" then
              if not tostring(value):match("^[^@]+@[^@]+%.[^@]+$") then
                table.insert(errors, { field = full_path, message = "Field '" .. full_path .. "' is not a valid email", line = 1, col = 1 })
              end
            end
          elseif field_type == "integer" or field_type == "number" then
            if field_schema.minimum and value < field_schema.minimum then
              table.insert(errors, { field = full_path, message = "Field '" .. full_path .. "' is less than minimum " .. field_schema.minimum, line = 1, col = 1 })
            end
            if field_schema.maximum and value > field_schema.maximum then
              table.insert(errors, { field = full_path, message = "Field '" .. full_path .. "' is greater than maximum " .. field_schema.maximum, line = 1, col = 1 })
            end
          end
        end
      end
      -- If field is missing and has a default, do not error (default is used)
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
