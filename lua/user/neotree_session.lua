local M = {}

local STATE_DIR = vim.fs.joinpath(vim.fn.stdpath "state", "astro-neotree-sessions")

local function state_file(cwd)
  cwd = vim.fs.normalize(cwd or vim.fn.getcwd())
  return vim.fs.joinpath(STATE_DIR, vim.fn.sha256(cwd) .. ".json")
end

local function read_json(path)
  local ok, content = pcall(vim.fn.readfile, path)
  if not ok or not content then return nil end

  local decoded_ok, decoded = pcall(vim.json.decode, table.concat(content, "\n"), { luanil = { object = true } })
  return decoded_ok and decoded or nil
end

local function write_json(path, data)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile({ vim.json.encode(data) }, path)
end

local function existing_directories(paths)
  local directories = {}

  for _, path in ipairs(paths or {}) do
    if type(path) == "string" and vim.fn.isdirectory(path) == 1 then
      table.insert(directories, vim.fs.normalize(path))
    end
  end

  return directories
end

local function filesystem_state()
  local ok_manager, manager = pcall(require, "neo-tree.sources.manager")
  if not ok_manager then return nil end

  local state = manager.get_state "filesystem"
  if not state or not state.tree then return nil end

  return state
end

function M.save()
  local state = filesystem_state()
  if not state then return end

  local ok_renderer, renderer = pcall(require, "neo-tree.ui.renderer")
  if not ok_renderer then return end

  local selected = state.tree:get_node()
  local selected_path = selected and selected:get_id() or nil
  local expanded = existing_directories(renderer.get_expanded_nodes(state.tree, state.path))

  write_json(state_file(), {
    cwd = vim.fs.normalize(vim.fn.getcwd()),
    root = vim.fs.normalize(state.path or vim.fn.getcwd()),
    expanded = expanded,
    selected = selected_path and vim.fs.normalize(selected_path) or nil,
    updated_at = os.time(),
  })
end

function M.restore()
  local data = read_json(state_file())
  if not data then return end

  local cwd = vim.fs.normalize(vim.fn.getcwd())
  if data.cwd ~= cwd then return end

  local expanded = existing_directories(data.expanded)
  if #expanded == 0 then return end

  local state = filesystem_state()
  if not state then return end

  local ok_fs, filesystem = pcall(require, "neo-tree.sources.filesystem")
  local ok_renderer, renderer = pcall(require, "neo-tree.ui.renderer")
  if not (ok_fs and ok_renderer) then return end

  state.force_open_folders = expanded
  state.explicitly_opened_nodes = state.explicitly_opened_nodes or {}
  for _, path in ipairs(expanded) do
    state.explicitly_opened_nodes[path] = true
  end

  local selected = type(data.selected) == "string" and data.selected or nil
  local root = vim.fn.isdirectory(data.root) == 1 and data.root or cwd

  filesystem.navigate(state, root, selected, function()
    if state.tree then
      pcall(renderer.set_expanded_nodes, state.tree, expanded)
      if selected then pcall(renderer.focus_node, state, selected, true) end
      pcall(renderer.redraw, state)
    end
  end, false)
end

return M
