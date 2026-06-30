local M = {}

local loaded = false
local cached_context

local function agent_context_enabled()
  local agent = vim.env.DOTAGENT_AGENT
  local editor_prompt = vim.env.DOTAGENT_EDITOR_PROMPT
  return editor_prompt
    and editor_prompt ~= ""
    and (agent == "codex" or agent == "claude" or agent == "claude-code")
end

local function number_from_env(name, default, minimum)
  local value = tonumber(vim.env[name])
  if not value or value < minimum then return default end
  return math.floor(value)
end

local function strip_control_chars(line)
  line = line:gsub("\27%[[0-?]*[ -/]*[@-~]", "")
  return line:gsub("%c", function(char)
    if char == "\t" then return char end
    return ""
  end)
end

local function truncate_line(line)
  local max_chars = number_from_env("NVIM_PRE_SHELL_CONTEXT_MAX_LINE_CHARS", 300, 40)
  if vim.fn.strchars(line) <= max_chars then return line end
  return vim.fn.strcharpart(line, 0, max_chars) .. " ..."
end

local function redact_line(line)
  local lower = line:lower()
  line = line:gsub("([Aa]uthorization:%s*[Bb]earer%s+)%S+", "%1[REDACTED]")

  if
    lower:match "api[_%-]?key%s*[=:]"
    or lower:match "token%s*[=:]"
    or lower:match "secret%s*[=:]"
    or lower:match "password%s*[=:]"
  then
    line = line:gsub("([=:]%s*)%S+", "%1[REDACTED]", 1)
  end

  return line
end

local function trim_empty_edges(lines)
  while #lines > 0 and lines[1]:match "^%s*$" do
    table.remove(lines, 1)
  end

  while #lines > 0 and lines[#lines]:match "^%s*$" do
    table.remove(lines)
  end

  return lines
end

local function tail_lines(lines)
  local max_lines = number_from_env("NVIM_PRE_SHELL_CONTEXT_MAX_LINES", 120, 1)
  if #lines <= max_lines then return lines end

  local trimmed = {}
  for index = #lines - max_lines + 1, #lines do
    trimmed[#trimmed + 1] = lines[index]
  end
  table.insert(trimmed, 1, "[earlier shell context omitted]")
  return trimmed
end

local function tail_chars(text)
  local max_chars = number_from_env("NVIM_PRE_SHELL_CONTEXT_MAX_CHARS", 2500, 200)
  local length = vim.fn.strchars(text)
  if length <= max_chars then return text end
  return "[earlier shell context omitted]\n" .. vim.fn.strcharpart(text, length - max_chars)
end

local function load_context()
  if loaded then return cached_context end
  loaded = true

  if not agent_context_enabled() then return nil end

  local path = vim.env.NVIM_PRE_SHELL_CONTEXT
  if not path or path == "" then return nil end
  if vim.fn.filereadable(path) ~= 1 then
    M.cleanup()
    return nil
  end

  local ok, lines = pcall(vim.fn.readfile, path)
  M.cleanup()

  if not ok or not lines or #lines == 0 then return nil end

  lines = trim_empty_edges(lines)
  lines = tail_lines(lines)
  lines = vim.tbl_map(function(line)
    return truncate_line(redact_line(strip_control_chars(line)))
  end, lines)

  local text = vim.trim(tail_chars(table.concat(lines, "\n")))
  if text == "" then return nil end

  cached_context = text
  return cached_context
end

local function comment_line(line)
  local commentstring = vim.bo.commentstring
  if commentstring and commentstring ~= "" and commentstring:find "%%s" then
    local commented = commentstring:gsub("%%s", function() return line end, 1)
    return commented
  end
  return "# " .. line
end

function M.comment_block()
  local context = load_context()
  if not context then return "" end

  local lines = vim.split(context, "\n", { plain = true })
  local commented = { comment_line "Shell context before Neovim:" }
  for _, line in ipairs(lines) do
    commented[#commented + 1] = comment_line(line)
  end

  return table.concat(commented, "\n")
end

function M.fim_prompt(context_before_cursor, _, _)
  local utils = require "minuet.utils"
  local parts = {
    utils.add_language_comment(),
    utils.add_tab_comment(),
    M.comment_block(),
    context_before_cursor,
  }

  local non_empty = {}
  for _, part in ipairs(parts) do
    if part and part ~= "" then non_empty[#non_empty + 1] = part end
  end

  return table.concat(non_empty, "\n")
end

function M.fim_suffix(_, context_after_cursor, _) return context_after_cursor end

function M.cleanup()
  local path = vim.env.NVIM_PRE_SHELL_CONTEXT
  if vim.env.NVIM_PRE_SHELL_CONTEXT_DELETE == "1" and path and path ~= "" then
    pcall(vim.fn.delete, path)
  end
  vim.env.NVIM_PRE_SHELL_CONTEXT = nil
  vim.env.NVIM_PRE_SHELL_CONTEXT_DELETE = nil
end

return M
