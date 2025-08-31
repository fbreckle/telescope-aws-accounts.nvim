local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require('telescope.pickers.entry_display')

local aws_ini_parser = require("telescope._extensions.aws_account_picker.aws_ini_parser")

-- Create a displayer function with two columns
local displayer = entry_display.create({
  separator = " ",
  items = {
    -- it is surprisingly difficult to get the precise picker width and then calculate a proper display width
    -- these values work good enough heuristically, i.e. it looks good down in windows down to 60 columns
    {width = 0.7},
    {width = 0.3, right_justify = true},
  },
})

local get_entry_display = function (entry)
  return displayer(
    {
      { entry.name, "TelescopeResultsIdentifier" },
      { entry.sso_account_id, "TelescopeResultsComment"},
    }
  )
end

--- this function takes an entry
-- and renders a preview table
local function get_previewer_lines(entry)
  local lines = {
    "Account Name: " .. entry.value.name,
    "Account ID: " .. entry.value.sso_account_id,
  }
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

  -- if aws config should parsed, parse it and add to results
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
      entry_maker = function(entry)
        return {
          value = entry,
          display = function() return get_entry_display(entry) end,
          ordinal = entry.sso_account_id .. entry.name,
        }
      end
    },
    -- use a default sorter
    sorter = conf.generic_sorter(opts),
    -- add a simple buffer previewer
    previewer = previewers.new_buffer_previewer {
      title = 'AWS Account Preview',
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
        vim.api.nvim_put({ selection.value.sso_account_id }, "", false, true)
      end)
      return true
    end,
  }):find()
end

return aws_account_picker
