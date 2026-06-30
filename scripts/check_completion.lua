local failures = {}

local function fail(message) table.insert(failures, message) end

local function assert_true(value, message)
  if not value then fail(message) end
end

local function has(list, value)
  for _, item in ipairs(list or {}) do
    if item == value then return true end
  end
  return false
end

local function value_of(value, ...)
  if type(value) == "function" then return value(...) end
  return value
end

local function labels_from_current_buffer(source, line)
  local result
  source:get_completions({
    bufnr = vim.api.nvim_get_current_buf(),
    line = line,
    cursor = { 1, #line },
  }, function(items) result = items end)

  local labels = {}
  for _, item in ipairs((result and result.items) or {}) do
    labels[#labels + 1] = item.label
  end
  return labels
end

local function labels_from_source(source, filetype, line)
  vim.cmd "enew!"
  vim.bo.filetype = filetype
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { line })
  vim.bo.modified = false

  return labels_from_current_buffer(source, line)
end

local function provider_ids_for(filetype, line)
  local context = require "user.completion_context"
  local providers
  for index = 1, 20 do
    local name, value = debug.getupvalue(context.trigger, index)
    if name == "providers_for_context" then
      providers = value
      break
    end
  end
  return providers and providers(filetype, line) or {}
end

local function assert_context_trigger(filetype, line, expected_provider, message)
  vim.cmd "enew!"
  vim.bo.filetype = filetype
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { line })

  local virtualedit = vim.o.virtualedit
  vim.o.virtualedit = "onemore"
  vim.api.nvim_win_set_cursor(0, { 1, #line })
  vim.bo.modified = false

  local shown
  require("user.completion_context").trigger(vim.api.nvim_get_current_buf(), {
    mode = "i",
    defer_fn = function(callback) callback() end,
    cmp = {
      show = function(opts) shown = opts.providers end,
    },
  })
  vim.o.virtualedit = virtualedit

  assert_true(has(shown, expected_provider), message)
end

local function assert_retrigger_same_position()
  vim.cmd "enew!"
  vim.bo.filetype = "typescript"

  local virtualedit = vim.o.virtualedit
  vim.o.virtualedit = "onemore"

  local shown = 0
  local cmp = {
    show = function() shown = shown + 1 end,
  }
  local trigger_opts = {
    mode = "i",
    defer_fn = function(callback) callback() end,
    cmp = cmp,
  }

  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "import" })
  vim.api.nvim_win_set_cursor(0, { 1, #"import" })
  vim.bo.modified = false
  require("user.completion_context").trigger(vim.api.nvim_get_current_buf(), trigger_opts)

  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "export" })
  vim.api.nvim_win_set_cursor(0, { 1, #"export" })
  vim.bo.modified = false
  require("user.completion_context").trigger(vim.api.nvim_get_current_buf(), trigger_opts)

  vim.o.virtualedit = virtualedit
  assert_true(shown == 2, "context trigger should rerun when text changes at same cursor position")
end

require("lazy").load { plugins = { "blink.cmp" } }

local blink_config = require "blink.cmp.config"
assert_true(has(value_of(blink_config.sources.default), "buffer"), "default sources should include buffer fallback")
assert_true(
  has(value_of(blink_config.sources.per_filetype.python), "python_imports"),
  "python sources should include python_imports"
)
assert_true(
  has(value_of(blink_config.sources.per_filetype.typescript), "js_imports"),
  "typescript sources should include js_imports"
)
assert_true(value_of(blink_config.sources.providers.lsp.async, {}) == true, "lsp source should be async")
assert_true(value_of(blink_config.sources.providers.lsp.timeout_ms, {}) == 250, "lsp timeout should stay low")
assert_true(
  value_of(blink_config.sources.providers.buffer.min_keyword_length, {}) == 3,
  "buffer fallback should trigger at 3 chars"
)
assert_true(
  value_of(blink_config.sources.providers.buffer.max_items, {}, {}) == 8,
  "buffer fallback should stay capped"
)

local astrolsp_opts = require("lazy.core.config").plugins.astrolsp.opts.config
assert_true(
  astrolsp_opts.basedpyright.settings.basedpyright.analysis.autoImportCompletions == true,
  "basedpyright auto import completions should stay enabled"
)
assert_true(
  astrolsp_opts.basedpyright.settings.basedpyright.analysis.diagnosticMode == "openFilesOnly",
  "basedpyright diagnostics should avoid full-workspace default load"
)
assert_true(
  astrolsp_opts.vtsls.settings.typescript.suggest.includeCompletionsForImportStatements == true,
  "vtsls should keep import-statement completions enabled"
)
assert_true(
  astrolsp_opts.vtsls.settings.typescript.suggest.autoImports == true,
  "vtsls should keep auto imports enabled"
)
assert_true(
  astrolsp_opts.vtsls.settings.typescript.tsserver.maxTsServerMemory == 4096,
  "vtsls should keep increased tsserver memory"
)

local completion_autocmds = vim.api.nvim_get_autocmds { event = "TextChangedI" }
local has_context_autocmd = false
for _, autocmd in ipairs(completion_autocmds) do
  if autocmd.desc == "Trigger completion in language import contexts" then
    has_context_autocmd = true
    break
  end
end
assert_true(has_context_autocmd, "TextChangedI context completion autocmd should be registered")

local python_source = require("user.blink_python_imports").new()
assert_true(
  has(labels_from_source(python_source, "python", "from"), "from module import name"),
  "python exact 'from' should offer template"
)
assert_true(
  has(labels_from_source(python_source, "python", "import"), "import module"),
  "python exact 'import' should offer template"
)
assert_true(
  has(labels_from_source(python_source, "python", "from "), "os"),
  "python 'from ' should offer modules immediately"
)
assert_true(
  has(labels_from_source(python_source, "python", "from os import "), "path"),
  "python 'from os import ' should offer common members"
)
assert_true(
  has(labels_from_source(python_source, "python", "from typing import "), "Any"),
  "python typing imports should offer common members"
)

local js_source = require("user.blink_js_imports").new()
assert_true(
  has(labels_from_source(js_source, "typescript", "import"), "default import"),
  "typescript exact 'import' should offer templates"
)
assert_true(
  has(labels_from_source(js_source, "typescript", "export"), "named export from module"),
  "typescript exact 'export' should offer templates"
)

local temp = vim.fn.tempname()
vim.fn.mkdir(temp .. "/src/components", "p")
vim.fn.writefile({
  vim.json.encode {
    dependencies = {
      react = "latest",
      zod = "latest",
    },
  },
}, temp .. "/package.json")
vim.fn.writefile({ "export const localThing = 1" }, temp .. "/src/local.ts")
vim.fn.writefile({ "export const Button = () => null" }, temp .. "/src/components/Button.tsx")
vim.cmd("edit " .. vim.fn.fnameescape(temp .. "/src/main.ts"))
vim.bo.filetype = "typescript"
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'import x from "' })
vim.bo.modified = false
local module_labels = labels_from_current_buffer(js_source, 'import x from "')
assert_true(has(module_labels, "react"), "typescript module specifier should include package deps")
assert_true(has(module_labels, "./local"), "typescript module specifier should include local modules")

assert_true(
  has(provider_ids_for("python", "from"), "python_imports"),
  "context trigger should use python_imports for exact from"
)
assert_true(
  has(provider_ids_for("python", "from os import "), "python_imports"),
  "context trigger should use python_imports for member imports"
)
assert_true(
  has(provider_ids_for("typescript", "import"), "js_imports"),
  "context trigger should use js_imports for exact import"
)
assert_true(
  has(provider_ids_for("typescript", 'import x from "'), "js_imports"),
  "context trigger should use js_imports for module specifiers"
)
assert_context_trigger("python", "from", "python_imports", "trigger should show blink menu for python exact from")
assert_context_trigger(
  "python",
  "from os import ",
  "python_imports",
  "trigger should show blink menu for python member imports"
)
assert_context_trigger(
  "typescript",
  "import",
  "js_imports",
  "trigger should show blink menu for typescript exact import"
)
assert_context_trigger(
  "typescript",
  'import x from "',
  "js_imports",
  "trigger should show blink menu for typescript module specifiers"
)
assert_retrigger_same_position()

vim.cmd "enew!"
vim.bo.filetype = "python"
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  "local_symbol_for_completion = 1",
  "local_symbol_for_compute = 2",
  "loc",
})
vim.api.nvim_win_set_cursor(0, { 3, 3 })
vim.bo.modified = false

local buffer_source = require("blink.cmp.sources.buffer").new(blink_config.sources.providers.buffer.opts)
local buffer_result
buffer_source:get_completions({}, function(items) buffer_result = items end)
vim.wait(1000, function() return buffer_result ~= nil end)
local buffer_labels = {}
for _, item in ipairs((buffer_result and buffer_result.items) or {}) do
  buffer_labels[#buffer_labels + 1] = item.label
end
assert_true(has(buffer_labels, "local_symbol_for_completion"), "buffer fallback should return current-buffer symbols")

if #failures > 0 then
  for _, message in ipairs(failures) do
    print("FAIL: " .. message)
  end
  os.exit(1)
end

print "completion checks passed"
