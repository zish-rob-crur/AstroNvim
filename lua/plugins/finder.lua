local function open_finder_for_current_file()
  if vim.fn.has "mac" ~= 1 then
    vim.notify("Finder reveal is currently configured only for macOS", vim.log.levels.WARN)
    return
  end

  local path = vim.api.nvim_buf_get_name(0)
  if path ~= "" then
    vim.fn.jobstart({ "open", "-R", vim.fn.fnamemodify(path, ":p") }, { detach = true })
    return
  end

  vim.fn.jobstart({ "open", vim.fn.getcwd() }, { detach = true })
end

---@type LazySpec
return {
  {
    "AstroNvim/astrocore",
    optional = true,
    opts = function(_, opts)
      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}
      opts.mappings.n["<Leader>fo"] = { open_finder_for_current_file, desc = "Reveal current file in Finder" }
      return opts
    end,
  },
}
