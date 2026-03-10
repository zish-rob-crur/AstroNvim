local function open_finder_for_current_file()
  if vim.fn.has "mac" ~= 1 then
    vim.notify("当前只为 macOS 配置了访达打开动作", vim.log.levels.WARN)
    return
  end

  local path = vim.api.nvim_buf_get_name(0)
  local target = path ~= "" and vim.fn.fnamemodify(path, ":p:h") or vim.fn.getcwd()

  vim.fn.jobstart({ "open", target }, { detach = true })
end

---@type LazySpec
return {
  {
    "AstroNvim/astrocore",
    optional = true,
    opts = function(_, opts)
      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}
      opts.mappings.n["<Leader>fo"] = { open_finder_for_current_file, desc = "Open current file dir in Finder" }
      return opts
    end,
  },
}
