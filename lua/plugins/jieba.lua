local jieba_instance

-- LuaRocks installs its xmake build backend into the plugin's private tree.
-- Expose that tree to the LuaRocks subprocess during a clean first install.
local rocks_root = vim.fn.stdpath "data" .. "/lua-rocks"
local jieba_rocks_lua = rocks_root .. "/jieba.nvim/share/lua/5.1"
local luarocks_lua_path = table.concat({ jieba_rocks_lua .. "/?.lua", jieba_rocks_lua .. "/?/init.lua" }, ";")
local jieba_rocks_cpath = rocks_root .. "/jieba.nvim/lib/lua/5.1/?.so"

if not (vim.env.LUA_PATH or ""):find(jieba_rocks_lua, 1, true) then
  vim.env.LUA_PATH = luarocks_lua_path .. ";" .. (vim.env.LUA_PATH or ";;")
end
if not package.path:find(jieba_rocks_lua, 1, true) then package.path = luarocks_lua_path .. ";" .. package.path end
if not package.cpath:find(jieba_rocks_cpath, 1, true) then package.cpath = jieba_rocks_cpath .. ";" .. package.cpath end

local jieba_rocks_bin = rocks_root .. "/jieba.nvim/bin"
if not (vim.env.PATH or ""):find(jieba_rocks_bin, 1, true) then
  vim.env.PATH = jieba_rocks_bin .. ":" .. (vim.env.PATH or "")
end

local function load_jieba_wrapper()
  if package.loaded["cppjieba.jieba"] then return end

  -- Load the rock directly so lazy.nvim does not select the Git checkout's
  -- incomplete Lua wrapper (the dictionaries only exist in the rock tree).
  if not package.loaded.cppjieba then
    local binary = rocks_root .. "/jieba.nvim/lib/lua/5.1/cppjieba.so"
    local load_binary, binary_err = package.loadlib(binary, "luaopen_cppjieba")
    assert(load_binary, binary_err)
    package.loaded.cppjieba = load_binary()
  end

  local wrapper = jieba_rocks_lua .. "/cppjieba/jieba.lua"
  local load_wrapper, wrapper_err = loadfile(wrapper)
  assert(load_wrapper, wrapper_err)
  package.loaded["cppjieba.jieba"] = load_wrapper()
end

local function is_han_codepoint(codepoint)
  return (codepoint >= 0x3400 and codepoint <= 0x4DBF)
    or (codepoint >= 0x4E00 and codepoint <= 0x9FFF)
    or (codepoint >= 0xF900 and codepoint <= 0xFAFF)
    or (codepoint >= 0x20000 and codepoint <= 0x2FA1F)
    or (codepoint >= 0x30000 and codepoint <= 0x323AF)
end

local function contains_han(text)
  local index = 1

  while index <= #text do
    local first = text:byte(index)
    local codepoint, width

    if first < 0x80 then
      codepoint, width = first, 1
    elseif first >= 0xC2 and first <= 0xDF and index + 1 <= #text then
      local second = text:byte(index + 1)
      codepoint, width = (first - 0xC0) * 0x40 + (second - 0x80), 2
    elseif first >= 0xE0 and first <= 0xEF and index + 2 <= #text then
      local second, third = text:byte(index + 1, index + 2)
      codepoint = (first - 0xE0) * 0x1000 + (second - 0x80) * 0x40 + (third - 0x80)
      width = 3
    elseif first >= 0xF0 and first <= 0xF4 and index + 3 <= #text then
      local second, third, fourth = text:byte(index + 1, index + 3)
      codepoint = (first - 0xF0) * 0x40000 + (second - 0x80) * 0x1000 + (third - 0x80) * 0x40 + (fourth - 0x80)
      width = 4
    else
      codepoint, width = first, 1
    end

    if is_han_codepoint(codepoint) then return true end
    index = index + width
  end

  return false
end

local function get_jieba()
  if jieba_instance then return jieba_instance end

  load_jieba_wrapper()

  -- Reuse the instance created for w/b/e/ge so the dictionary is loaded once.
  local wordmotion = require "wordmotion.nvim.jieba"
  wordmotion.init()
  jieba_instance = assert(wordmotion.motion and wordmotion.motion.jieba, "Failed to initialize cppjieba")

  -- This binding's generated destructor crashes on macOS when Lua runs GC.
  -- Keep the single native dictionary alive until the process releases it.
  local native_metatable = debug.getmetatable(jieba_instance.jieba)
  if native_metatable then native_metatable.__gc = nil end

  return jieba_instance
end

local function setup_word_motions()
  local mappings = {
    w = { modes = { "n", "x" }, begin = true, forward = true },
    b = { modes = { "n", "x" }, begin = true, forward = false },
    e = { modes = { "n", "x" }, begin = false, forward = true },
    ge = { modes = { "n", "x" }, begin = false, forward = false },
    iw = { modes = { "x" }, around = false },
    aw = { modes = { "x" }, around = true },
  }

  for lhs, mapping in pairs(mappings) do
    vim.keymap.set(mapping.modes, lhs, function()
      get_jieba()
      local begin_or_around = mapping.around
      if begin_or_around == nil then begin_or_around = mapping.begin end
      require("wordmotion.nvim.jieba").motion:keymap(begin_or_around, mapping.forward)
    end, { desc = "Jieba word motion " .. lhs })
  end
end

local function is_jump_target(line, token, byte_col)
  if token == "" or (not token:find "[%w_]" and not contains_han(token)) then return false end

  -- Treat hyphenated ASCII text as one target: only label its first segment.
  if token:match "^[%w_]+$" and byte_col > 0 and line:sub(byte_col, byte_col) == "-" then return false end

  return true
end

local function jieba_matcher(win)
  local buf = vim.api.nvim_win_get_buf(win)
  if vim.bo[buf].buftype ~= "" then return {} end

  local first_line, last_line

  vim.api.nvim_win_call(win, function()
    first_line = vim.fn.line "w0"
    last_line = vim.fn.line "w$"
  end)

  local lines = vim.api.nvim_buf_get_lines(buf, first_line - 1, last_line, false)
  local matches = {}
  local jieba = get_jieba()

  for line_offset, line in ipairs(lines) do
    local byte_col = 0

    for _, token in ipairs(jieba:cut(line)) do
      if is_jump_target(line, token, byte_col) then
        local pos = { first_line + line_offset - 1, byte_col }
        matches[#matches + 1] = {
          pos = pos,
          -- Flash uses end_pos to place an "after" label. Keeping the range
          -- at the first byte makes the label overlay the token's first glyph.
          end_pos = pos,
        }
      end

      byte_col = byte_col + #token
    end
  end

  return matches
end

local function label_code(index, labels, width)
  local code = {}

  for position = width, 1, -1 do
    local digit = (index - 1) % #labels + 1
    code[position] = labels[digit]
    index = math.floor((index - 1) / #labels) + 1
  end

  return table.concat(code)
end

local function hierarchical_labeler(matches, state)
  local labels = state:labels()
  if #labels == 0 then return end

  local width, capacity = 1, #labels
  while capacity < #matches do
    width = width + 1
    capacity = capacity * #labels
  end

  local prefix = state.pattern()
  for index, match in ipairs(matches) do
    local code = label_code(index, labels, width)
    if code:sub(1, #prefix) == prefix then
      local remaining = code:sub(#prefix + 1)
      match.label = remaining ~= "" and remaining or false
    else
      match.label = false
    end
  end
end

local function jump_to_chinese_word()
  require("flash").jump {
    matcher = jieba_matcher,
    labeler = hierarchical_labeler,
    search = {
      -- The matcher ignores the typed pattern. It is used only as the prefix
      -- for hierarchical labels when visible targets exceed the alphabet.
      max_length = false,
      multi_window = true,
    },
    label = {
      uppercase = false,
      before = false,
      after = { 0, 0 },
      style = "overlay",
      -- Keep the complete hierarchical code internally, but only render the
      -- next key. This cuts visual width without changing the input sequence.
      format = function(opts) return { { opts.match.label:sub(1, 1), opts.hl_group } } end,
    },
    highlight = {
      matches = false,
      backdrop = true,
    },
    jump = {
      pos = "start",
      autojump = false,
    },
  }
end

return {
  {
    "neo451/jieba.nvim",
    lazy = true,
    module = false,
    init = setup_word_motions,
  },
  {
    "folke/flash.nvim",
    keys = {
      {
        "<Leader>jw",
        jump_to_chinese_word,
        mode = { "n", "x", "o" },
        desc = "Jump to Chinese word",
      },
    },
  },
}
