local uv = vim.uv or vim.loop

local M = {}

local JS_EXTENSIONS = {
  js = true,
  jsx = true,
  ts = true,
  tsx = true,
  mjs = true,
  cjs = true,
  json = true,
}

local cache = {}

local function is_js_filetype(filetype)
  return vim.tbl_contains({
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
  }, filetype)
end

local function root_for(bufnr)
  return vim.fs.root(bufnr, { "package.json", "tsconfig.json", "jsconfig.json", ".git" }) or vim.fn.getcwd()
end

local function read_json(path)
  if vim.fn.filereadable(path) ~= 1 then return nil end

  local lines = vim.fn.readfile(path)
  if vim.tbl_isempty(lines) then return nil end

  local ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  if ok then return decoded end
end

local function add(seen, items, label, detail)
  if type(label) ~= "string" or label == "" or seen[label] then return end
  seen[label] = true
  table.insert(items, { label = label, detail = detail })
end

local function package_modules(root, seen, items)
  local package_json = read_json(root .. "/package.json")
  if not package_json then return end

  for _, section in ipairs { "dependencies", "devDependencies", "peerDependencies", "optionalDependencies" } do
    local deps = package_json[section]
    if type(deps) == "table" then
      local names = vim.tbl_keys(deps)
      table.sort(names)
      for _, name in ipairs(names) do
        add(seen, items, name, section)
      end
    end
  end
end

local function stat(path) return uv.fs_stat(path) end

local function has_index_module(dir)
  for ext in pairs(JS_EXTENSIONS) do
    if stat(dir .. "/index." .. ext) then return true end
  end
  return false
end

local function module_label(current_dir, path, is_dir)
  local import_path = vim.fs.relpath(current_dir, path)
  if not import_path then return nil end
  import_path = import_path:gsub("\\", "/")
  if not import_path:match "^%." then import_path = "./" .. import_path end

  if not is_dir then
    import_path = import_path:gsub("%.[%w]+$", "")
    import_path = import_path:gsub("/index$", "")
  end

  if import_path == "." then return nil end
  return import_path
end

local function scan_modules(root, current_dir, current_file, dir, seen, items, depth)
  if depth > 4 or #items > 300 then return end

  local handle = uv.fs_scandir(dir)
  if not handle then return end

  while true do
    local name, kind = uv.fs_scandir_next(handle)
    if not name then break end
    if name:sub(1, 1) ~= "." and name ~= "node_modules" and name ~= "dist" and name ~= "build" then
      local path = dir .. "/" .. name
      if kind == "file" then
        local ext = name:match "%.([%w]+)$"
        if ext and JS_EXTENSIONS[ext] and not name:match "%.d%.ts$" and path ~= current_file then
          add(seen, items, module_label(current_dir, path, false), "local module")
        end
      elseif kind == "directory" then
        if has_index_module(path) then add(seen, items, module_label(current_dir, path, true), "local module") end
        scan_modules(root, current_dir, current_file, path, seen, items, depth + 1)
      end
    end
  end
end

local function all_modules(bufnr)
  local root = root_for(bufnr)
  local current_file = vim.api.nvim_buf_get_name(bufnr)
  local current_dir = current_file ~= "" and vim.fs.dirname(current_file) or root
  local key = root .. "\n" .. current_dir

  if cache[key] then return cache[key] end

  local seen, items = {}, {}
  package_modules(root, seen, items)
  scan_modules(root, current_dir, current_file, root, seen, items, 0)

  cache[key] = items
  return items
end

local function import_syntax(ctx)
  if not is_js_filetype(vim.bo[ctx.bufnr].filetype) then return nil end

  local before = ctx.line:sub(1, ctx.cursor[2])
  local kind = before:match "^%s*(import)%s*$" or before:match "^%s*(export)%s*$"
  if not kind then return nil end
  local start_col = #(before:match "^%s*" or "")

  return {
    kind = kind,
    range = {
      start = { line = ctx.cursor[1] - 1, character = start_col },
      ["end"] = { line = ctx.cursor[1] - 1, character = ctx.cursor[2] },
    },
  }
end

local function specifier_range(ctx)
  if not is_js_filetype(vim.bo[ctx.bufnr].filetype) then return nil end

  local before = ctx.line:sub(1, ctx.cursor[2])
  if
    not (
      before:match [[from%s+["'][%w@%./_-]*$]]
      or before:match [[import%s*%(%s*["'][%w@%./_-]*$]]
      or before:match [[^%s*import%s+["'][%w@%./_-]*$]]
      or before:match [[export%s+.*from%s+["'][%w@%./_-]*$]]
    )
  then
    return nil
  end

  local quote_pos = before:match ".*()[\"']"
  if not quote_pos then return nil end

  return {
    start = { line = ctx.cursor[1] - 1, character = quote_pos },
    ["end"] = { line = ctx.cursor[1] - 1, character = ctx.cursor[2] },
  }
end

function M.new() return setmetatable({}, { __index = M }) end

function M:enabled() return is_js_filetype(vim.bo.filetype) end

function M:get_completions(ctx, callback)
  local syntax = import_syntax(ctx)
  if syntax then
    local snippet_kind = require("blink.cmp.types").CompletionItemKind.Snippet
    local snippet = vim.lsp.protocol.InsertTextFormat.Snippet
    local templates = syntax.kind == "export"
        and {
          { "named export from module", [[export { ${1:name} } from "${2:module}"]] },
          { "export all from module", [[export * from "${1:module}"]] },
          { "type export from module", [[export type { ${1:Name} } from "${2:module}"]] },
        }
      or {
        { "default import", [[import ${1:name} from "${2:module}"]] },
        { "named import", [[import { ${1:name} } from "${2:module}"]] },
        { "namespace import", [[import * as ${1:name} from "${2:module}"]] },
        { "type import", [[import type { ${1:Name} } from "${2:module}"]] },
        { "side-effect import", [[import "${1:module}"]] },
      }

    local items = {}
    for index, item in ipairs(templates) do
      items[index] = {
        label = item[1],
        kind = snippet_kind,
        detail = syntax.kind .. " template",
        insertTextFormat = snippet,
        textEdit = {
          newText = item[2],
          range = syntax.range,
        },
        sortText = ("%04d_%s"):format(index, item[1]),
      }
    end

    callback {
      is_incomplete_forward = false,
      is_incomplete_backward = false,
      items = items,
    }
    return
  end

  local range = specifier_range(ctx)
  if not range then
    callback { is_incomplete_forward = false, is_incomplete_backward = false, items = {} }
    return
  end

  local kind_module = require("blink.cmp.types").CompletionItemKind.Module
  local plain_text = vim.lsp.protocol.InsertTextFormat.PlainText
  local items = {}

  for index, module in ipairs(all_modules(ctx.bufnr)) do
    items[index] = {
      label = module.label,
      kind = kind_module,
      detail = module.detail,
      insertTextFormat = plain_text,
      textEdit = {
        newText = module.label,
        range = range,
      },
      sortText = ("%04d_%s"):format(index, module.label),
    }
  end

  callback {
    is_incomplete_forward = true,
    is_incomplete_backward = true,
    items = items,
  }
end

return M
