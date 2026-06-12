local M = {}

local PATHLIKE_FILETYPES = {
  markdown = true,
  text = true,
}

local function line_before_cursor(ctx) return ctx.line:sub(1, ctx.cursor[2]) end

local function current_file_dir(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then return vim.fn.getcwd() end
  return vim.fs.dirname(name) or vim.fn.getcwd()
end

local function path_token(ctx)
  local before = line_before_cursor(ctx)
  local quoted_token = before:match [[["'`]%s*([%w%._~/%-]+)$]]
  if quoted_token then return quoted_token end

  if PATHLIKE_FILETYPES[vim.bo[ctx.bufnr].filetype] then
    local bracket_token = before:match [[[%(%[]%s*([%w%._~/%-]+)$]]
    if bracket_token then return bracket_token end
  end

  local token = before:match [[[%s:]([%w%._~/%-]+)$]] or before:match [[^([%w%._~/%-]+)$]]
  if not token or token == "" then return nil end

  local has_path_signal = token:find("/", 1, true) ~= nil or token:match "^[%.~]"
  if not has_path_signal and not PATHLIKE_FILETYPES[vim.bo[ctx.bufnr].filetype] then return nil end

  return token
end

local function resolve_base(ctx, token)
  local base
  local rel = token

  if token:sub(1, 2) == "~/" then
    base = vim.fn.expand "~"
    rel = token:sub(3)
  elseif token:sub(1, 1) == "/" then
    base = "/"
    rel = token:sub(2)
  elseif token:sub(1, 2) == "./" or token:sub(1, 3) == "../" then
    base = current_file_dir(ctx.bufnr)
  else
    base = vim.fn.getcwd()
  end

  local dir_part = rel:match "^(.*)/[^/]*$"
  local prefix = rel:match "([^/]*)$" or ""
  local dir = dir_part and vim.fs.normalize(vim.fs.joinpath(base, dir_part)) or vim.fs.normalize(base)

  return dir, prefix
end

local function scandir(dir, prefix, limit)
  local handle = vim.uv.fs_scandir(dir)
  if not handle then return {} end

  local items = {}
  local include_hidden = prefix:sub(1, 1) == "."
  local kind = require("blink.cmp.types").CompletionItemKind
  local plain_text = vim.lsp.protocol.InsertTextFormat.PlainText

  while #items < limit do
    local name, type = vim.uv.fs_scandir_next(handle)
    if not name then break end
    if name ~= ".git" and (include_hidden or name:sub(1, 1) ~= ".") and vim.startswith(name, prefix) then
      local is_dir = type == "directory"
      local insert_text = is_dir and name .. "/" or name
      table.insert(items, {
        label = insert_text,
        kind = is_dir and kind.Folder or kind.File,
        insertText = insert_text,
        insertTextFormat = plain_text,
        detail = vim.fs.relpath(vim.fn.getcwd(), vim.fs.joinpath(dir, name)) or dir,
        sortText = (is_dir and "1" or "2") .. name:lower(),
      })
    end
  end

  table.sort(items, function(a, b) return a.sortText < b.sortText end)
  return items
end

function M.new() return setmetatable({}, { __index = M }) end

function M:get_completions(ctx, callback)
  local token = path_token(ctx)
  if not token then
    callback { is_incomplete_forward = false, is_incomplete_backward = false, items = {} }
    return
  end

  local dir, prefix = resolve_base(ctx, token)
  local start_col = ctx.cursor[2] - #prefix
  local items = scandir(dir, prefix, 80)

  for _, item in ipairs(items) do
    item.textEdit = {
      newText = item.insertText,
      range = {
        start = { line = ctx.cursor[1] - 1, character = start_col },
        ["end"] = { line = ctx.cursor[1] - 1, character = ctx.cursor[2] },
      },
    }
  end

  callback {
    is_incomplete_forward = true,
    is_incomplete_backward = true,
    items = items,
  }
end

return M
