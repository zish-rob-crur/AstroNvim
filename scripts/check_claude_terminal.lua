local source = debug.getinfo(1, "S").source:gsub("^@", "")
local repo = vim.fs.dirname(vim.fs.dirname(vim.fn.fnamemodify(source, ":p")))
vim.opt.runtimepath:prepend(repo)
local claude = require "user.claude_terminal"
local codex = require "user.codex_terminal"
claude.setup()
codex.setup()
local root = vim.fn.tempname()
vim.fn.mkdir(root, "p")
root = assert(vim.uv.fs_realpath(root))
vim.fn.writefile({}, root .. "/CLAUDE.md")
local path = root .. "/notes with spaces.md"
vim.cmd.edit(vim.fn.fnameescape(path))
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "first", "second" })
vim.api.nvim_win_set_cursor(0, { 2, 0 })
local editor = vim.api.nvim_get_current_win()
local options = { command = { "sh", "-c", "sleep 30" }, prefill_delay_ms = 0 }
local sent = {}
local chansend = vim.fn.chansend
vim.fn.chansend = function(job, data)
  sent[#sent + 1] = { job, data }
  return #data
end
local instance = assert(claude.attach_current(options))
assert(instance.root == root, "must find CLAUDE.md project root")
assert(vim.deep_equal(vim.fn.readfile(path), { "first", "second" }), "must save before attaching")
assert(sent[1][2] == "\27[200~current edit: notes with spaces.md:2 \27[201~", "must prefill context without submitting")
assert(vim.bo[instance.bufnr].filetype == "zish_claude_terminal")
assert(vim.wo[instance.winid].number == false and vim.wo[instance.winid].winbar == "")
assert(vim.fn.maparg("<M-h>", "t") ~= "" and vim.fn.maparg("<F7>", "t") ~= "")
vim.api.nvim_set_current_win(editor)
assert(claude.attach_current(options) == instance, "must focus existing instance")
assert(#sent == 1, "same context must not be duplicated")
claude.hide(root)
vim.api.nvim_set_current_win(editor)
vim.api.nvim_win_set_cursor(0, { 1, 0 })
assert(claude.attach_current(options) == instance, "hidden session must be reused")
assert(sent[2][2]:find("notes with spaces.md:1", 1, true), "new line must be attached")
vim.api.nvim_set_current_win(editor)
local other = assert(codex.open { root = root, command = options.command })
assert(other.job_id ~= instance.job_id, "Claude and Codex must have separate sessions")
local job = instance.job_id
claude.close(root)
assert(vim.fn.jobwait({ job }, 0)[1] ~= -1, "closing must stop Claude")
assert(vim.fn.jobwait({ other.job_id }, 0)[1] == -1, "closing Claude must preserve Codex")
codex.close(root)
vim.fn.chansend = chansend
vim.fn.delete(root, "rf")
print "check_claude_terminal: ok"
