-- Shared cppjieba instance for word motions and pinyin jumps.

local M = {}

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

-- Returns the cppjieba instance shared with the w/b/e/ge motions, loading the
-- dictionary on first use (about 150 ms).
function M.get()
  if jieba_instance then return jieba_instance end

  load_jieba_wrapper()

  local wordmotion = require "wordmotion.nvim.jieba"
  wordmotion.init()
  jieba_instance = assert(wordmotion.motion and wordmotion.motion.jieba, "Failed to initialize cppjieba")

  -- This binding's generated destructor crashes on macOS when Lua runs GC.
  -- Keep the single native dictionary alive until the process releases it.
  local native_metatable = debug.getmetatable(jieba_instance.jieba)
  if native_metatable then native_metatable.__gc = nil end

  return jieba_instance
end

return M
