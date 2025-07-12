local M = {}

local utils = require('jsonvalid8.utils')

--- Parses simplified schema syntax and returns a JSON Schema table or error.
-- @param lines table: lines of schema definition
-- @return table: JSON Schema, or nil and error message
function M.parse(lines)
  local schema = {
    type = "object",
    properties = {},
    required = {}
  }
  
  local current_object = nil
  local object_stack = {}
  
  for line_num, line in ipairs(lines) do
    local trimmed = line:match("^%s*(.-)%s*$")
    if trimmed ~= "" and not trimmed:match("^#") then
      local success, result = pcall(M.parse_line, trimmed, line_num)
      if not success then
        return nil, "Error on line " .. line_num .. ": " .. result
      end
      
      if result then
        if result.type == "object_start" then
          -- Start of object definition
          table.insert(object_stack, current_object)
          current_object = result.field
        elseif result.type == "object_end" then
          -- End of object definition
          current_object = table.remove(object_stack)
        elseif result.type == "field" then
          -- Regular field definition
          local field_path = result.field
          if current_object then
            field_path = current_object .. "." .. field_path
          end
          
          -- Add to properties
          M.add_property(schema, field_path, result.schema)
          
          -- Add to required if not optional
          if not result.optional then
            table.insert(schema.required, field_path:match("([^.]+)$"))
          end
        end
      end
    end
  end
  
  return schema
end

--- Parse a single line of schema definition
function M.parse_line(line, line_num)
  -- Match field name and type definition
  local field_name, type_def = line:match("^([%w_]+)%s*:%s*(.+)$")
  if not field_name then
    return nil
  end
  
  -- Check if field is optional
  local optional = field_name:match("(.+)?$")
  if optional then
    field_name = optional
  end
  
  -- Parse type definition
  local schema, default_value = M.parse_type_definition(type_def)
  if not schema then
    error("Invalid type definition: " .. type_def)
  end
  
  -- Add default value if specified
  if default_value then
    schema.default = default_value
  end
  
  return {
    type = "field",
    field = field_name,
    schema = schema,
    optional = optional ~= nil
  }
end

--- Parse type definition (e.g., "string", "integer(minimum=0)", "array[string]")
function M.parse_type_definition(type_def)
  -- Handle default values
  local base_type, default = type_def:match("^(.+?)%s*=%s*(.+)$")
  if not base_type then
    base_type = type_def
  end
  
  -- Parse array types
  local array_match = base_type:match("^array%[(.+)%]$")
  if array_match then
    local item_schema = M.parse_type_definition(array_match)
    if not item_schema then
      return nil
    end
    
    local schema = {
      type = "array",
      items = item_schema
    }
    
    -- Parse default value for arrays
    if default then
      if default == "[]" then
        schema.default = {}
      else
        -- Try to parse as JSON array
        local success, result = pcall(vim.fn.json_decode, default)
        if success and type(result) == "table" then
          schema.default = result
        end
      end
    end
    
    return schema
  end
  
  -- Parse object types
  local object_match = base_type:match("^object%{(.+)%}$")
  if object_match then
    -- For now, return a simple object schema
    -- In a full implementation, you'd parse the nested object definition
    return {
      type = "object",
      properties = {},
      additionalProperties = false
    }
  end
  
  -- Parse enum types
  local enum_match = base_type:match("^enum%[(.+)%]$")
  if enum_match then
    local values = {}
    for value in enum_match:gmatch("([^,]+)") do
      table.insert(values, value:match("^%s*(.-)%s*$"))
    end
    return {
      type = "string",
      enum = values
    }
  end
  
  -- Parse basic types with constraints
  local type_name, constraints = base_type:match("^([%w]+)%((.+)%)$")
  if not type_name then
    type_name = base_type
  end
  
  local schema = { type = type_name }
  
  -- Parse constraints
  if constraints then
    for constraint in constraints:gmatch("([^,]+)") do
      local key, value = constraint:match("^%s*([%w]+)%s*=%s*(.+)$")
      if key and value then
        -- Convert value to appropriate type
        if value:match("^%d+$") then
          schema[key] = tonumber(value)
        elseif value:match("^%d+%.%d+$") then
          schema[key] = tonumber(value)
        elseif value == "true" then
          schema[key] = true
        elseif value == "false" then
          schema[key] = false
        else
          -- Remove quotes if present
          schema[key] = value:match("^[\"'](.+)[\"']$") or value
        end
      end
    end
  end
  
  -- Parse default value for basic types
  if default then
    if type_name == "string" then
      schema.default = default:match("^[\"'](.+)[\"']$") or default
    elseif type_name == "integer" or type_name == "number" then
      schema.default = tonumber(default)
    elseif type_name == "boolean" then
      schema.default = (default == "true")
    end
  end
  
  return schema
end

--- Add property to schema, handling nested paths
function M.add_property(schema, field_path, property_schema)
  local parts = utils.split(field_path, ".")
  local current = schema.properties
  
  for i = 1, #parts - 1 do
    local part = parts[i]
    if not current[part] then
      current[part] = {
        type = "object",
        properties = {}
      }
    end
    current = current[part].properties
  end
  
  current[parts[#parts]] = property_schema
end

return M
