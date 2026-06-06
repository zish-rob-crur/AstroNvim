local uv = vim.uv or vim.loop

local M = {}

local COMMON_MODULES = {
  "os",
  "sys",
  "pathlib",
  "typing",
  "collections",
  "dataclasses",
  "itertools",
  "functools",
  "json",
  "re",
  "datetime",
  "asyncio",
  "logging",
  "argparse",
  "subprocess",
  "math",
  "random",
  "statistics",
  "decimal",
  "fractions",
  "time",
  "sqlite3",
  "csv",
  "urllib",
  "http",
  "email",
  "unittest",
  "pytest",
  "requests",
  "numpy",
  "pandas",
  "pydantic",
  "fastapi",
  "django",
  "flask",
  "sqlalchemy",
}

local COMMON_MEMBERS = {
  asyncio = { "create_task", "gather", "run", "sleep", "Queue", "Task" },
  collections = { "Counter", "defaultdict", "deque", "namedtuple", "OrderedDict" },
  dataclasses = { "dataclass", "field", "asdict", "astuple", "replace" },
  datetime = { "datetime", "date", "time", "timedelta", "timezone" },
  functools = { "cache", "cached_property", "lru_cache", "partial", "reduce", "wraps" },
  itertools = { "chain", "combinations", "count", "cycle", "groupby", "islice", "product", "repeat" },
  json = { "dump", "dumps", "load", "loads", "JSONDecodeError" },
  logging = { "debug", "info", "warning", "error", "exception", "getLogger", "Logger" },
  os = { "path", "environ", "getcwd", "chdir", "getenv", "listdir", "makedirs", "remove", "rename", "stat", "walk" },
  pathlib = { "Path", "PurePath", "PosixPath", "WindowsPath" },
  re = { "compile", "search", "match", "fullmatch", "sub", "findall", "Pattern", "Match" },
  subprocess = { "run", "Popen", "PIPE", "CalledProcessError", "CompletedProcess" },
  sys = { "argv", "path", "exit", "stderr", "stdin", "stdout", "version", "platform" },
  typing = {
    "Any",
    "Callable",
    "Dict",
    "Iterable",
    "Iterator",
    "List",
    "Literal",
    "Optional",
    "Protocol",
    "Sequence",
    "TypeAlias",
    "TypeVar",
    "Union",
    "cast",
    "overload",
  },
}

local cache = {
  python_started = false,
  python_modules = nil,
  member_started = {},
  module_members = {},
  project_root = nil,
  project_modules = nil,
}

local function add_module(seen, modules, name)
  if type(name) ~= "string" then return end
  if not name:match "^[%a_][%w_]*$" or name:match "^_" or seen[name] then return end
  seen[name] = true
  table.insert(modules, name)
end

local function scan_dir(dir, seen, modules)
  local handle = uv.fs_scandir(dir)
  if not handle then return end

  while true do
    local name, kind = uv.fs_scandir_next(handle)
    if not name then break end
    if name:sub(1, 1) ~= "." then
      if kind == "file" then
        local module_name = name:match "^([%a_][%w_]*)%.py$"
        if module_name then add_module(seen, modules, module_name) end
      elseif kind == "directory" and uv.fs_stat(dir .. "/" .. name .. "/__init__.py") then
        add_module(seen, modules, name)
      end
    end
  end
end

local function project_modules()
  local root = vim.fs.root(0, { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" })
    or vim.fn.getcwd()
  if cache.project_root == root and cache.project_modules then return cache.project_modules end

  local seen, modules = {}, {}
  scan_dir(root, seen, modules)
  scan_dir(root .. "/src", seen, modules)
  table.sort(modules)

  cache.project_root = root
  cache.project_modules = modules
  return modules
end

local function refresh_python_modules()
  if cache.python_started then return end
  cache.python_started = true

  local python = vim.fn.exepath "python3"
  if python == "" then python = vim.fn.exepath "python" end
  if python == "" or not vim.system then return end

  local script = [[
import pkgutil
import sys

names = set(getattr(sys, "stdlib_module_names", ()))
names.update(module.name for module in pkgutil.iter_modules())
for name in sorted(names):
    if name.isidentifier() and not name.startswith("_"):
        print(name)
]]

  vim.system({ python, "-c", script }, { text = true }, function(result)
    if result.code ~= 0 or not result.stdout then return end
    local seen, modules = {}, {}
    for name in result.stdout:gmatch "[^\r\n]+" do
      add_module(seen, modules, name)
    end
    vim.schedule(function() cache.python_modules = modules end)
  end)
end

local function all_modules()
  refresh_python_modules()

  local seen, modules = {}, {}
  for _, name in ipairs(project_modules()) do
    add_module(seen, modules, name)
  end
  for _, name in ipairs(COMMON_MODULES) do
    add_module(seen, modules, name)
  end
  for _, name in ipairs(cache.python_modules or {}) do
    add_module(seen, modules, name)
  end
  return modules
end

local function refresh_module_members(module)
  if cache.member_started[module] then return end
  cache.member_started[module] = true

  if not module:match "^[%a_][%w_%.]*$" then return end

  local python = vim.fn.exepath "python3"
  if python == "" then python = vim.fn.exepath "python" end
  if python == "" or not vim.system then return end

  local script = [[
import importlib
import sys

try:
    module = importlib.import_module(sys.argv[1])
except Exception:
    raise SystemExit(1)

names = getattr(module, "__all__", None) or dir(module)
for name in sorted(names):
    if isinstance(name, str) and name.isidentifier() and not name.startswith("_"):
        print(name)
]]

  vim.system({ python, "-c", script, module }, { text = true }, function(result)
    if result.code ~= 0 or not result.stdout then return end
    local seen, members = {}, {}
    for name in result.stdout:gmatch "[^\r\n]+" do
      add_module(seen, members, name)
    end
    vim.schedule(function() cache.module_members[module] = members end)
  end)
end

local function all_members(module)
  refresh_module_members(module)

  local seen, members = {}, {}
  for _, name in ipairs(COMMON_MEMBERS[module] or {}) do
    add_module(seen, members, name)
  end
  for _, name in ipairs(cache.module_members[module] or {}) do
    add_module(seen, members, name)
  end
  return members
end

local function in_module_import_context(ctx)
  if vim.bo[ctx.bufnr].filetype ~= "python" then return false end

  local before = ctx.line:sub(1, ctx.cursor[2])
  if before:match "^%s*from%s+[%w_%.]*$" then return true end

  local import_tail = before:match "^%s*import%s+(.*)$"
  if import_tail then
    local current_part = import_tail:match "([^,]*)$" or import_tail
    return current_part:match "^%s*[%w_%.]*$" ~= nil
  end

  return false
end

local function member_import_module(ctx)
  if vim.bo[ctx.bufnr].filetype ~= "python" then return nil end

  local before = ctx.line:sub(1, ctx.cursor[2])
  local module, import_tail = before:match "^%s*from%s+([%w_%.]+)%s+import%s*(.*)$"
  if not module or module == "" then return nil end

  local current_part = import_tail:match "([^,]*)$" or import_tail
  if current_part:match "^%s*[%w_]*$" then return module end
end

local function import_statement_template(ctx)
  if vim.bo[ctx.bufnr].filetype ~= "python" then return nil end

  local before = ctx.line:sub(1, ctx.cursor[2])
  local keyword = before:match "^%s*(from)$" or before:match "^%s*(import)$"
  if not keyword then return nil end

  local start_col = ctx.cursor[2] - #keyword
  local snippet_kind = require("blink.cmp.types").CompletionItemKind.Snippet
  local snippet = vim.lsp.protocol.InsertTextFormat.Snippet

  return {
    is_incomplete_forward = false,
    is_incomplete_backward = false,
    items = keyword == "from" and {
      {
        label = "from module import name",
        kind = snippet_kind,
        detail = "python import template",
        insertTextFormat = snippet,
        textEdit = {
          newText = [[from ${1:module} import ${2:name}]],
          range = {
            start = { line = ctx.cursor[1] - 1, character = start_col },
            ["end"] = { line = ctx.cursor[1] - 1, character = ctx.cursor[2] },
          },
        },
        sortText = "0001_from_module_import_name",
      },
    } or {
      {
        label = "import module",
        kind = snippet_kind,
        detail = "python import template",
        insertTextFormat = snippet,
        textEdit = {
          newText = [[import ${1:module}]],
          range = {
            start = { line = ctx.cursor[1] - 1, character = start_col },
            ["end"] = { line = ctx.cursor[1] - 1, character = ctx.cursor[2] },
          },
        },
        sortText = "0001_import_module",
      },
    },
  }
end

function M.new() return setmetatable({}, { __index = M }) end

function M:enabled() return vim.bo.filetype == "python" end

function M:get_completions(ctx, callback)
  local template = import_statement_template(ctx)
  if template then
    callback(template)
    return
  end

  local import_module = member_import_module(ctx)
  if import_module then
    local member_kind = require("blink.cmp.types").CompletionItemKind.Variable
    local plain_text = vim.lsp.protocol.InsertTextFormat.PlainText
    local items = {}

    for index, name in ipairs(all_members(import_module)) do
      items[index] = {
        label = name,
        kind = member_kind,
        insertText = name,
        insertTextFormat = plain_text,
        detail = "from " .. import_module .. " import",
        sortText = ("%04d_%s"):format(index, name),
      }
    end

    callback {
      is_incomplete_forward = true,
      is_incomplete_backward = true,
      items = items,
    }
    return
  end

  if not in_module_import_context(ctx) then
    callback { is_incomplete_forward = false, is_incomplete_backward = false, items = {} }
    return
  end

  local module_kind = require("blink.cmp.types").CompletionItemKind.Module
  local plain_text = vim.lsp.protocol.InsertTextFormat.PlainText
  local items = {}

  for index, name in ipairs(all_modules()) do
    items[index] = {
      label = name,
      kind = module_kind,
      insertText = name,
      insertTextFormat = plain_text,
      detail = "python module",
      sortText = ("%04d_%s"):format(index, name),
    }
  end

  callback {
    is_incomplete_forward = true,
    is_incomplete_backward = true,
    items = items,
  }
end

return M
