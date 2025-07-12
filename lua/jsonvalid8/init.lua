local M = {}

local config = require('jsonvalid8.config')

M.setup = function(user_config)
  config.setup(user_config)
end

M.open = function()
  require('jsonvalid8.ui').open()
end

M.validate = function()
  require('jsonvalid8.validator').validate()
end

M.clear = function()
  require('jsonvalid8.ui').clear()
end

M.templates = function()
  require('jsonvalid8.schemas').show_templates()
end

M.export = function()
  require('jsonvalid8.schemas').export()
end

return M
