local M = {}

M.dark_colorscheme = "everforest"
M.light_colorscheme = "github_light_high_contrast"
M.dark_background = "medium"

function M.mode()
  if vim.env.NVIM_THEME_MODE == "dark" or vim.env.NVIM_THEME_MODE == "light" then
    return vim.env.NVIM_THEME_MODE
  end

  if vim.fn.has "mac" == 0 then return vim.o.background == "dark" and "dark" or "light" end

  local output = vim.fn.system { "defaults", "read", "-g", "AppleInterfaceStyle" }
  return vim.v.shell_error == 0 and output:match "Dark" and "dark" or "light"
end

function M.colorscheme(mode)
  mode = mode or M.mode()
  return mode == "dark" and M.dark_colorscheme or M.light_colorscheme
end

function M.background(mode)
  mode = mode or M.mode()
  return mode == "dark" and M.dark_background or "github-light-high-contrast"
end

function M.configure(mode)
  mode = mode or M.mode()
  vim.o.background = mode
  if mode == "dark" then
    vim.g.everforest_background = M.background(mode)
    vim.g.everforest_enable_italic = 1
    vim.g.everforest_better_performance = 1
  end
end

function M.highlights(mode)
  mode = mode or M.mode()
  if mode == "dark" then
    return {
      GitSignsCurrentLineBlame = { fg = "#7fbbb3", bg = "#343f44", italic = true },
    }
  end

  return {
    GitSignsCurrentLineBlame = { fg = "#0969da", bg = "#ddf4ff", italic = true },
  }
end

function M.apply()
  local mode = M.mode()
  local colorscheme = M.colorscheme(mode)
  local background = M.background(mode)

  if
    vim.g.colors_name == colorscheme
    and vim.o.background == mode
    and (mode == "light" or vim.g.everforest_background == background)
  then
    return
  end

  M.configure(mode)
  local ok, err = pcall(vim.cmd.colorscheme, colorscheme)
  if not ok then
    vim.notify(("Error setting colorscheme `%s`: %s"):format(colorscheme, err), vim.log.levels.ERROR)
    return
  end

  pcall(function() require("astroui.status.heirline").refresh_colors() end)
  vim.cmd.redrawstatus()
end

function M.setup_auto_sync()
  if M._auto_sync_started then return end
  M._auto_sync_started = true

  local group = vim.api.nvim_create_augroup("user_macos_theme_sync", { clear = true })
  vim.api.nvim_create_autocmd({ "FocusGained", "VimResume" }, {
    group = group,
    callback = function() vim.schedule(M.apply) end,
  })
end

return M
