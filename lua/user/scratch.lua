local M = {}

local DEFAULT_DIR = "~/Documents/scratch"

local function create_file(dir)
  dir = vim.fs.normalize(vim.fn.expand(dir or DEFAULT_DIR))

  local created, mkdir_result = pcall(vim.fn.mkdir, dir, "p")
  if not created or (mkdir_result == 0 and vim.fn.isdirectory(dir) == 0) then
    return nil, "Could not create scratch directory: " .. dir
  end

  local uv = vim.uv or vim.loop
  local timestamp = os.date "%Y-%m-%d-%H%M%S"
  local suffix = 0

  while true do
    local filename = timestamp .. (suffix == 0 and "" or "-" .. (suffix + 1)) .. ".md"
    local path = vim.fs.joinpath(dir, filename)
    local fd, open_error = uv.fs_open(path, "wx", 420)

    if fd then
      uv.fs_close(fd)
      return path
    end

    if not uv.fs_stat(path) then return nil, "Could not create scratch file: " .. tostring(open_error) end
    suffix = suffix + 1
  end
end

function M.new_markdown(dir)
  local path, err = create_file(dir)
  if not path then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  vim.cmd.edit(vim.fn.fnameescape(path))
  vim.notify("Created scratch note: " .. vim.fn.fnamemodify(path, ":~"))
  return path
end

return M
