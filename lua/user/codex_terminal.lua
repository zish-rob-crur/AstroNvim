local trust_profile = "edit-anywhere"

local function configured_mcp_servers(root)
  local codex_home = vim.env.CODEX_HOME or vim.fn.expand "~/.codex"
  local names = {}
  for _, path in ipairs {
    vim.fs.joinpath(codex_home, "config.toml"),
    vim.fs.joinpath(root, ".codex", "config.toml"),
  } do
    local ok, lines = pcall(vim.fn.readfile, path)
    if ok then
      for _, line in ipairs(lines) do
        local name = line:match "^%s*%[mcp_servers%.([%w_-]+)"
        if name then names[name] = true end
      end
    end
  end
  return vim.tbl_keys(names)
end

local function ensure_trust_profile(root, codex_home)
  codex_home = codex_home or vim.env.CODEX_HOME or vim.fn.expand "~/.codex"
  local path = vim.fs.joinpath(codex_home, trust_profile .. ".config.toml")
  local project_key = root:gsub("\\", "\\\\"):gsub('"', '\\"')
  local header = ('[projects."%s"]'):format(project_key)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then lines = {} end
  if vim.tbl_contains(lines, header) then return true end

  if #lines > 0 and lines[#lines] ~= "" then table.insert(lines, "") end
  vim.list_extend(lines, { header, 'trust_level = "trusted"' })
  local written, err = pcall(vim.fn.writefile, lines, path)
  if not written then vim.notify("Could not update Codex trust profile: " .. err, vim.log.levels.ERROR) end
  return written
end

local function codex_command(root, mcp_servers)
  local command = {
    "codex",
    "-p",
    trust_profile,
    "--disable",
    "apps",
    "--disable",
    "plugins",
    "--disable",
    "remote_plugin",
    "-c",
    "check_for_update_on_startup=false",
  }
  table.sort(mcp_servers)
  for _, name in ipairs(mcp_servers) do
    vim.list_extend(command, { "-c", ("mcp_servers.%s.enabled=false"):format(name) })
  end
  vim.list_extend(command, { "-C", root })
  return command
end

local terminal = require("user.agent_terminal").new {
  name = "Codex",
  map_exit = true,
  command = function(root)
    ensure_trust_profile(root)
    return codex_command(root, configured_mcp_servers(root))
  end,
}
terminal._codex_command_for_test = codex_command
terminal._ensure_trust_profile_for_test = ensure_trust_profile
return terminal
