local M = {}

local inactive_fg = 0x6E7781
local inactive_bg = 0xF6F8FA
local fg_blend = 0.36
local bg_blend = 0.45

local state = {
  enabled = true,
  dimmed = false,
  snapshot = nil,
}

local skip = {
  Cursor = true,
  CursorIM = true,
  CurSearch = true,
  IncSearch = true,
  Search = true,
  TermCursor = true,
  TermCursorNC = true,
  Visual = true,
  VisualNOS = true,
}

local function in_tmux() return vim.env.TMUX ~= nil and vim.env.TMUX ~= "" end

local function is_enabled() return state.enabled and vim.g.tmux_focus_dim_enabled ~= false and in_tmux() end

local function channel(value)
  return {
    bit.rshift(value, 16),
    bit.band(bit.rshift(value, 8), 0xFF),
    bit.band(value, 0xFF),
  }
end

local function blend(value, target, amount)
  if not value then return nil end

  local source_rgb = channel(value)
  local target_rgb = channel(target)
  local result = 0

  for index = 1, 3 do
    local mixed = math.floor(source_rgb[index] * (1 - amount) + target_rgb[index] * amount + 0.5)
    result = bit.lshift(result, 8) + mixed
  end

  return result
end

local function dim_attrs(name, attrs)
  if skip[name] then return attrs end

  local dimmed = vim.deepcopy(attrs)
  dimmed.fg = attrs.fg and blend(attrs.fg, inactive_fg, fg_blend) or attrs.fg
  dimmed.bg = attrs.bg and blend(attrs.bg, inactive_bg, bg_blend) or attrs.bg
  dimmed.sp = attrs.sp and blend(attrs.sp, inactive_fg, fg_blend) or attrs.sp

  return dimmed
end

function M.apply()
  if state.dimmed or not is_enabled() then return end

  local snapshot = vim.api.nvim_get_hl(0, { link = true })
  state.snapshot = snapshot

  for name, _ in pairs(snapshot) do
    local ok, resolved = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    if ok and type(resolved) == "table" and next(resolved) ~= nil then
      vim.api.nvim_set_hl(0, name, dim_attrs(name, resolved))
    end
  end

  state.dimmed = true
end

function M.restore()
  if not state.dimmed then return end

  local snapshot = state.snapshot or {}
  for name, attrs in pairs(snapshot) do
    vim.api.nvim_set_hl(0, name, attrs)
  end

  state.dimmed = false
  state.snapshot = nil
end

function M.refresh()
  if not state.dimmed then return end

  state.dimmed = false
  state.snapshot = nil
  vim.schedule(M.apply)
end

function M.toggle()
  state.enabled = not state.enabled
  if not state.enabled then M.restore() end
  vim.notify("tmux focus dim: " .. (state.enabled and "on" or "off"))
end

function M.setup()
  vim.api.nvim_create_user_command("TmuxFocusDimToggle", M.toggle, { force = true })
end

return M
