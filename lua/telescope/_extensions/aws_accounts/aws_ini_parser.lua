--- Extracts SSO profiles from a parsed AWS config
-- @param aws_config table The parsed AWS config
-- @return table An array containing the profile configuration
local extract_sso_profiles = function(aws_config)
  local output = {}
  local profile_name = nil
  for section, section_content in pairs(aws_config) do
    -- drop section if it is not a profile
    if section:find('^profile') and section_content["sso_account_id"] ~= nil then
      -- drop the "profile " prefix
      profile_name = section:sub(9)
      section_content["name"] = profile_name
      -- remap sso_account_id to id
      section_content["id"] = section_content["sso_account_id"]
      section_content["sso_account_id"] = nil
      table.insert(output, section_content)
    end
  end
  return output
end

--- Parses an AWS config ini file in the given path
-- @param path string The path of the file to parse
-- @return table A nested table with section names as keys and tables of key-value pairs as values.
local parse_aws_config = function(path)
  local config = {}
  local last_section = nil

  for line in io.lines(path) do
    line = vim.trim(line)
    -- skip empty lines and lines beginning with a comment
    if line ~= "" and not line:match("^#") then
      -- check if the given line is an ini section (by finding brackets)
      local section = line:match("^%[(.+)%]$")
      -- if we encounter a section, save it in last_section and initialize it
      -- all key value pairs that follow are in this section until we hit a new section
      if section then
        last_section = section
        config[last_section] = {}
      else
        -- extract key value pairs
        -- note that outer whitespace is already trimmed
        local key, value = line:match("^(.-)%s*=%s*(.+)$")
        if key and value then
          config[last_section][key] = value
        end
      end
    end
  end
  return config
end

return {
  parse_aws_config = parse_aws_config,
  extract_sso_profiles = extract_sso_profiles,
}
