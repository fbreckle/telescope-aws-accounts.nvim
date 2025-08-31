local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  error("This extension requires telescope.nvim")
end

local aws_account_picker = require("telescope._extensions.aws_accounts.picker")

return telescope.register_extension({
  exports = {
    aws_accounts = aws_account_picker
  },
})
