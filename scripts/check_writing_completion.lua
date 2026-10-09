-- Run with: nvim --headless -c 'luafile scripts/check_writing_completion.lua'
require("lazy").load { plugins = { "blink.cmp", "minuet-ai.nvim" } }

local context = require "user.completion_context"
local minuet = require "minuet"
local blink = require "blink.cmp.config"

local function buffer(ft)
  vim.cmd "enew!"
  vim.bo.filetype = ft
  vim.api.nvim_exec_autocmds("InsertEnter", { buffer = 0 })
end

for _, ft in ipairs { "markdown", "text", "" } do
  buffer(ft)
  assert(context.is_writing(), "prose buffer should use writing completion")
  assert(minuet.config.provider == "openai_compatible", "prose should use chat continuation")
  assert(not blink.completion.list.selection.preselect(), "Enter must not accept an unsolicited word")
  assert(not blink.completion.menu.auto_show({}, { { source_id = "buffer" } }), "hide automatic word menus")
  for _, source in ipairs { "path", "cwd_paths", "dotagent" } do
    assert(blink.completion.menu.auto_show({}, { { source_id = source } }), "keep explicit resource completion")
  end
end

vim.b.minuet_virtual_text_auto_trigger = false
vim.api.nvim_exec_autocmds("InsertEnter", { buffer = 0 })
assert(vim.b.minuet_virtual_text_auto_trigger == false, "respect the user's AI toggle")

buffer "lua"
assert(not context.is_writing() and minuet.config.provider == "openai_fim_compatible", "restore code completion")
assert(minuet.config.context_window == 6000 and minuet.config.request_timeout == 3, "restore code settings")
assert(blink.completion.menu.auto_show({}, { { source_id = "lsp" } }), "keep automatic code completion")
vim.b.dotagent_enabled = true
vim.api.nvim_exec_autocmds("InsertEnter", { buffer = 0 })
assert(minuet.config.provider == "openai_compatible", "Agent prompt activation takes precedence over filetype")
vim.bo.buftype = "nofile"
assert(not context.is_writing(), "exclude special buffers")

buffer "markdown"
local utils = require "minuet.utils"
local options = vim.deepcopy(minuet.config.provider_options.openai_compatible)
assert(#options.few_shots() == 0, "do not inherit coding examples")
local system = utils.make_system_prompt(options.system, 1)
assert(system:find("不要回答问题", 1, true), "continue the user's prompt instead of answering it")
local before, after = "请帮我检查这个函数，重点看", "，暂时不要修改代码。"
local messages = utils.make_chat_llm_shot({ lines_before = before, lines_after = after, opts = {} }, options.chat_input)
assert(messages[1]:find(before .. "<cursor/>" .. after, 1, true), "preserve Chinese prefix and suffix exactly")
assert(not messages[1]:find("# language:", 1, true), "do not inject code scaffolding into prose")

print "writing completion checks passed"
vim.cmd "qa!"
