-- Flash jump that also matches Chinese words by pinyin initials.
--
-- Typing `k` labels every literal "k" as usual, plus every Jieba word whose
-- first character can be read with the initial `k`; `kj` narrows to words whose
-- second character can be read with `j`, and so on across word boundaries.

local M = {}

local initials_by_offset

local function initials_of(codepoint)
  if not initials_by_offset then
    local table_spec = require "user.pinyin_initials"
    initials_by_offset = { first = table_spec.first }
    for entry in (table_spec.data .. "|"):gmatch "([^|]*)|" do
      initials_by_offset[#initials_by_offset + 1] = entry
    end
  end

  local entry = initials_by_offset[codepoint - initials_by_offset.first + 1]
  if entry and entry ~= "" then return entry end
end

-- Decodes the UTF-8 character starting at byte `index`.
local function decode(text, index)
  local first = text:byte(index)
  if not first then return nil, 0 end
  if first < 0x80 then return first, 1 end
  if first >= 0xC2 and first <= 0xDF and index + 1 <= #text then
    return (first - 0xC0) * 0x40 + (text:byte(index + 1) - 0x80), 2
  end
  if first >= 0xE0 and first <= 0xEF and index + 2 <= #text then
    local second, third = text:byte(index + 1, index + 2)
    return (first - 0xE0) * 0x1000 + (second - 0x80) * 0x40 + (third - 0x80), 3
  end
  if first >= 0xF0 and first <= 0xF4 and index + 3 <= #text then
    local second, third, fourth = text:byte(index + 1, index + 3)
    return (first - 0xF0) * 0x40000 + (second - 0x80) * 0x1000 + (third - 0x80) * 0x40 + (fourth - 0x80), 4
  end
  return first, 1
end

-- Matches `pattern` against the characters starting at byte `start` (1-based).
-- Returns the byte offset of the last matched character and the initials of
-- the character after the match, or nil when the pattern does not fit.
local function match_initials(line, start, pattern)
  local index, last_start = start, start
  for i = 1, #pattern do
    local codepoint, width = decode(line, index)
    local initials = codepoint and initials_of(codepoint)
    if not initials or not initials:find(pattern:sub(i, i), 1, true) then return nil end
    last_start, index = index, index + width
  end
  local next_codepoint = decode(line, index)
  return last_start, next_codepoint and initials_of(next_codepoint)
end

local function pinyin_matches(win, state, from, to)
  local pattern = state.pattern()
  local next_initials = {}
  if not pattern:match "^%l+$" then return {}, next_initials end

  local buf = vim.api.nvim_win_get_buf(win)
  local lines = vim.api.nvim_buf_get_lines(buf, from[1] - 1, to[1], false)
  local jieba = require("user.jieba").get()
  local matches = {}

  for offset, line in ipairs(lines) do
    if line:find "[\228-\233]" then
      local row = from[1] + offset - 1
      local byte_col = 0
      for _, token in ipairs(jieba:cut(line)) do
        local last_start, following = match_initials(line, byte_col + 1, pattern)
        if last_start then
          matches[#matches + 1] = { win = win, pos = { row, byte_col }, end_pos = { row, last_start - 1 } }
          for letter in (following or ""):gmatch "." do
            next_initials[letter] = true
          end
        end
        byte_col = byte_col + #token
      end
    end
  end

  return matches, next_initials
end

local function matcher(win, state, opts)
  local matches = require("flash.search").new(win, state):get(opts)
  local extra, next_initials = pinyin_matches(win, state, opts.from, opts.to)
  vim.list_extend(matches, extra)
  state.pinyin_next = state.pinyin_next or {}
  state.pinyin_next[win] = next_initials
  return matches
end

-- Flash's labeler already drops labels that could extend a literal match.
-- Do the same for letters that could extend a pinyin match.
local labelers = setmetatable({}, { __mode = "k" })

local function labeler(_, state)
  local instance = labelers[state]
  if not instance then
    instance = require("flash.labeler").new(state)
    local reset = instance.reset
    instance.reset = function(self)
      reset(self)
      local skip = {}
      for _, letters in pairs(state.pinyin_next or {}) do
        for letter in pairs(letters) do
          skip[letter] = true
        end
      end
      self.labels = vim.tbl_filter(function(label) return not skip[label:lower()] end, self.labels)
    end
    labelers[state] = instance
  end
  instance:update()
end

function M.jump(opts)
  require("flash").jump(vim.tbl_extend("force", { matcher = matcher, labeler = labeler }, opts or {}))
end

return M
