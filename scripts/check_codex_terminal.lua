local source = debug.getinfo(1, "S").source:gsub("^@", "")
local root = vim.fs.dirname(vim.fs.dirname(vim.fs.normalize(vim.fn.fnamemodify(source, ":p"))))
vim.opt.runtimepath:prepend(root)

local codex_terminal = require "user.codex_terminal"
codex_terminal.setup()
assert(vim.fn.maparg("ZZ", "n") ~= "", "ZZ must stop Codex while exiting the editor")
local source_buffer = vim.api.nvim_get_current_buf()
local source_window = vim.api.nvim_get_current_win()
vim.api.nvim_buf_set_name(source_buffer, root .. "/lua/user/codex_terminal.lua")
vim.api.nvim_win_set_cursor(0, { 1, 0 })
local context = assert(codex_terminal._file_context_for_test(source_buffer))
assert(context.root == root, "file context must use the repository root")
assert(context.relative == "lua/user/codex_terminal.lua", "file context must use a repository-relative path")
assert(context.line == 1, "file context must include the cursor line")
assert(context.prompt == "current edit: lua/user/codex_terminal.lua:1 ", "file context prompt must stay editable")

local command_root = root .. '/a project with "quotes"'
local command = codex_terminal._codex_command_for_test(command_root, { "slow_remote", "local-tools" })
local command_line = table.concat(command, "\n")
assert(command[1] == "codex", "default command must launch Codex")
assert(command[2] == "-p" and command[3] == "edit-anywhere", "embedded Codex must use its trust profile")
assert(command_line:find("--disable\napps"), "Codex apps MCP must be disabled")
assert(command_line:find("--disable\nplugins"), "plugin MCP servers must be disabled")
assert(command_line:find("--disable\nremote_plugin"), "remote plugin MCP servers must be disabled")
assert(command_line:find("mcp_servers.local%-tools.enabled=false"), "local MCP server must be disabled")
assert(command_line:find("mcp_servers.slow_remote.enabled=false"), "remote MCP server must be disabled")
assert(command[#command - 1] == "-C" and command[#command] == command_root, "default command must use the project root")

local test_codex_home = vim.fn.tempname()
vim.fn.mkdir(test_codex_home, "p")
assert(
  codex_terminal._ensure_trust_profile_for_test(command_root, test_codex_home),
  "current project must be persisted in the embedded Codex trust profile"
)
local trust_profile = vim.fn.readfile(vim.fs.joinpath(test_codex_home, "edit-anywhere.config.toml"))
assert(
  vim.tbl_contains(trust_profile, ('[projects."%s/a project with \\"quotes\\""]'):format(root)),
  "trust profile must quote the project path"
)
assert(vim.tbl_contains(trust_profile, 'trust_level = "trusted"'), "trust profile must mark the project trusted")
vim.fn.delete(test_codex_home, "rf")

local instance = assert(codex_terminal.open {
  root = root,
  command = { "sh", "-c", "sleep 5" },
  width = 0.4,
})

assert(vim.api.nvim_buf_is_valid(instance.bufnr), "terminal buffer must be valid")
assert(vim.api.nvim_win_is_valid(instance.winid), "terminal window must be valid")
assert(vim.bo[instance.bufnr].buftype == "terminal", "buffer must use the native terminal")
assert(vim.bo[instance.bufnr].buflisted == false, "terminal must stay out of the buffer tabline")
assert(vim.bo[instance.bufnr].filetype == "zish_codex_terminal", "terminal filetype is missing")
assert(vim.wo[instance.winid].winbar == "", "terminal winbar must be hidden")
assert(vim.wo[instance.winid].statuscolumn == "", "terminal statuscolumn must be hidden")
assert(vim.wo[instance.winid].number == false, "terminal line numbers must be hidden")
assert(vim.wo[instance.winid].signcolumn == "no", "terminal signcolumn must be hidden")
assert(#vim.api.nvim_list_wins() == 2, "terminal must open in a split")

assert(codex_terminal.hide(root), "terminal must hide")
assert(#vim.api.nvim_list_wins() == 1, "hiding terminal must preserve the editor window")
assert(vim.fn.jobwait({ instance.job_id }, 0)[1] == -1, "hidden terminal job must keep running")

local reopened = assert(codex_terminal.open {
  root = root,
  command = { "sh", "-c", "sleep 5" },
  width = 0.4,
})
assert(reopened.bufnr == instance.bufnr, "reopening must reuse the terminal buffer")
assert(reopened.job_id == instance.job_id, "reopening must reuse the terminal process")

vim.cmd "leftabove new"
vim.api.nvim_set_current_win(source_window)
assert(codex_terminal.exit_current_editor(), "ZZ lifecycle must exit the editor window")
assert(not vim.api.nvim_win_is_valid(source_window), "ZZ lifecycle must close the editor window")
assert(vim.fn.jobwait({ instance.job_id }, 0)[1] ~= -1, "ZZ lifecycle must stop the Codex job")

print "check_codex_terminal: ok"
