local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require('telescope.pickers.entry_display')

local aws_ini_parser = require("telescope._extensions.aws_accounts.aws_ini_parser")

-- Create a displayer function with two columns
local displayer = entry_display.create({
  separator = " ",
  items = {
    -- it is surprisingly difficult to get the precise picker width and then calculate a proper display width
    -- these values work good enough heuristically, i.e. it looks good down in windows down to 60 columns
    { width = 0.7 },
    { width = 0.3, right_justify = true },
  },
})

--- Renders the preview of an entry
-- @param entry table The entry to create the preview of
-- @return table The preview of the entry
local get_previewer_lines = function(entry)
  local lines = {
    "Name: " .. entry.value.name,
    "ID: " .. entry.value.id,
    "",
    "",
    "Additional information",
    "",
  }

  local key_to_nice_name_mapping = {
    sso_role_name = "SSO Role Name",
    sso_session = "SSO Session",
    sso_start_url = "SSO Start URL",
    sso_region = "SSO Region",
    sso_registration_scopes = "SSO Registration Scopes",
  }

  for k, v in pairs(entry.value) do
    -- we use lower key here, since aws config file keys are case-insensitive
    local lower_k = string.lower(k)
    -- generally, id and name are always passed first and therefore processed already
    -- so we ignore them here
    if lower_k ~= "id" and lower_k ~= "name" then
      -- the "nice key name" is either hard mapped from the table above or just the first letter capitalized
      local nice_key_name = key_to_nice_name_mapping[lower_k]
      if not nice_key_name then
        -- if we have no individual mapping for the key, just take the key and capitalize the first letter
        nice_key_name = lower_k:sub(1,1):upper() .. k:sub(2)
      end
      table.insert(lines, nice_key_name .. ": " .. v)
    end
  end
  return lines
end

local aws_account_picker = function(opts)
  opts = opts or {}

  -- set defaults
  opts = vim.tbl_extend("keep", opts, {
    parse_aws_config = true,
    aws_config_path = "~/.aws/config",
    static_accounts = {},
  })

  -- build results table
  local results = {}

  -- if aws config should be parsed, parse it and add to results
  if opts.parse_aws_config then
    local aws_config = aws_ini_parser.parse_aws_config(vim.fn.expand(opts.aws_config_path))
    local parsed_config = aws_ini_parser.extract_sso_profiles(aws_config)
    for _, v in ipairs(parsed_config) do
      table.insert(results, v)
    end
  end

  -- if static accounts are passed, add them now
  if opts.static_accounts then
    for _, v in ipairs(opts.static_accounts) do
      table.insert(results, v)
    end
  end

  pickers.new(opts, {
    prompt_title = "AWS Accounts",
    finder = finders.new_table {
      results = results,
      entry_maker = function(account_data)
        return {
          value = account_data,
          display = function()
            return displayer({
              { account_data.name, "TelescopeResultsIdentifier" },
              { account_data.id, "TelescopeResultsComment"},
            })
          end,
          ordinal = account_data.id .. account_data.name,
        }
      end
    },
    -- use a default sorter
    sorter = conf.generic_sorter(opts),
    -- add a simple buffer previewer
    previewer = previewers.new_buffer_previewer {
      title = 'AWS Account Details',
      define_preview = function(self, entry)
        local bufnr = self.state.bufnr
        local lines = get_previewer_lines(entry)
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
        vim.api.nvim_set_option_value('filetype', 'text', { buf = bufnr })
      end,
    },
    attach_mappings = function(prompt_bufnr)
      -- upon selection, insert account id of selected account
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if not selection then
          vim.notify("aws_account_picker: no selection made", vim.log.levels.WARN)
          return
        end
        -- perform the actual insert
        vim.api.nvim_put({ selection.value.id }, "", false, true)
      end)
      return true
    end,
  }):find()
end

return aws_account_picker
