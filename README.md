# telescope-aws-accounts.nvim

A [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) picker to quickly access your AWS accounts.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)

## Features

- Quickly find (and insert) the AWS account IDs of your AWS accounts
- Automatically parses your `.aws/config` file for AWS SSO account information
- Or pass a manual list of your relevant AWS accounts

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

### Add to telescope dependencies

```lua
return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    [...]
    -- AWS account picker
    { "fbreckle/telescope-aws-accounts.nvim" },
  },
  [...]
}
```

### Load extension

```lua
require("telescope").load_extension("aws_accounts")
```

To see if the extension is loaded, you can use

```vimscript
:checkhealth telescope
```

## Usage

To invoke the picker, you can use this snippet in your `init.lua` nvim configuration

```lua
-- Shortcut for searching AWS accounts
local telescope = require('telescope')
vim.keymap.set('n', '<leader>sa', function()
  telescope.extensions.aws_accounts.aws_accounts({
    -- available opts and their defaults:
    --
    -- the path of the aws config file to parse
    -- aws_config_path = "~/.aws/config",
    --
    -- whether to parse sso profiles from the AWS config at opts.aws_config_path
    -- parse_aws_config = true,
    --
    -- AWS accounts that are added to the list of accounts
    -- each aws account must be a table with a `name` and `sso_account_id` key
    -- static_accounts = {}
    --
    -- example:
    -- static_accounts = {
    --   { name = "aws-account-name-prod", sso_account_id = "123456789123" },
    --   { name = "aws-account-name-dev", sso_account_id = "123456789124" },
    -- },
  })
end, { desc = '[S]earch [A]WS accounts' })
```

You can then use `<leader>sa` to call the picker.

Selecting an entry with `<CR>` will insert the account ID of the selected AWS account at the current cursor position.
