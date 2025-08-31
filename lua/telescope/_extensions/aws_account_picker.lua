local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  error("This extension requires telescope.nvim")
end

local aws_account_picker = require("telescope._extensions.aws_account_picker.picker")

return telescope.register_extension({
  -- setup = function(ext_config, config)
  --   -- access extension config and user config
  -- end,
  exports = {
    aws_account_picker = aws_account_picker
  },
})
