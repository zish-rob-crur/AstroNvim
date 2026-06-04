local function save_session_and_reload()
  vim.cmd "silent! wall"

  local ok, resession = pcall(require, "resession")
  if ok then resession.save("Last Session", { notify = false }) end

  if vim.fn.exists ":AstroReload" == 2 then
    vim.cmd "AstroReload"
  else
    vim.cmd "runtime init.lua"
  end
end

return {
  {
    "AstroNvim/astrocore",
    optional = true,
    opts = function(_, opts)
      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}
      opts.mappings.n["<Leader>Sr"] = { save_session_and_reload, desc = "Save session and reload AstroNvim" }
      return opts
    end,
  },
}
