local DIRSESSION_DIR = "dirsession"

local function startup_has_no_args() return vim.fn.argc(-1) == 0 end

local function save_current_dirsession(notify)
  local ok_resession, resession = pcall(require, "resession")
  local ok_buffer, buffer = pcall(require, "astrocore.buffer")
  if ok_resession and ok_buffer and buffer.is_valid_session() then
    resession.save(vim.fn.getcwd(), { dir = DIRSESSION_DIR, notify = notify == true })
  end
end

local function is_existing_regular_target(path)
  return type(path) == "string" and path ~= "" and (vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 1)
end

local function current_dirsession_has_restorable_target()
  local ok_util, util = pcall(require, "resession.util")
  local ok_files, files = pcall(require, "resession.files")
  local ok_temp_file, temp_file = pcall(require, "user.temp_file")
  if not (ok_util and ok_files and ok_temp_file) then return true end

  local data = files.load_json_file(util.get_session_file(vim.fn.getcwd(), DIRSESSION_DIR))
  if not data then return false end

  for _, buffer in ipairs(data.buffers or {}) do
    if is_existing_regular_target(buffer.name) and not temp_file.is_path(buffer.name) then return true end
  end

  return false
end

local function load_current_dirsession()
  if not startup_has_no_args() then return end
  if not current_dirsession_has_restorable_target() then return end

  local ok, resession = pcall(require, "resession")
  if ok then resession.load(vim.fn.getcwd(), { dir = DIRSESSION_DIR, silence_errors = true }) end
end

local function save_session_and_reload()
  vim.cmd "silent! wall"

  local ok, resession = pcall(require, "resession")
  if ok then resession.save("Last Session", { notify = false }) end
  save_current_dirsession(false)

  if vim.fn.exists ":AstroReload" == 2 then
    vim.cmd "AstroReload"
  else
    vim.cmd "runtime init.lua"
  end
end

return {
  {
    "stevearc/resession.nvim",
    optional = true,
    opts = function(_, opts)
      local original_buf_filter = opts.buf_filter

      opts.buf_filter = function(bufnr)
        local ok, temp_file = pcall(require, "user.temp_file")
        if ok and temp_file.is_buffer(bufnr) then return false end
        if original_buf_filter then return original_buf_filter(bufnr) end
        local ok_buffer, buffer = pcall(require, "astrocore.buffer")
        if ok_buffer then return buffer.is_restorable(bufnr) end
        return require("resession").default_buf_filter(bufnr)
      end

      return opts
    end,
  },
  {
    "AstroNvim/astrocore",
    optional = true,
    opts = function(_, opts)
      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}
      opts.mappings.n["<Leader>Sr"] = { save_session_and_reload, desc = "Save session and reload AstroNvim" }

      opts.autocmds = opts.autocmds or {}
      opts.autocmds.auto_load_worktree_dirsession = {
        {
          event = "VimEnter",
          nested = true,
          desc = "Load current worktree dirsession on startup",
          callback = load_current_dirsession,
        },
      }

      return opts
    end,
  },
}
