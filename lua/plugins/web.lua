local function get_url_under_cursor()
  local url = vim.fn.expand "<cfile>"
  if type(url) ~= "string" or url == "" then return nil end
  if url:match "^https?://" then return url end
  return nil
end

local function open_w3m(url)
  if vim.fn.executable "w3m" ~= 1 then
    vim.notify("w3m is not installed", vim.log.levels.ERROR)
    return
  end
  if not url or url == "" then
    vim.notify("No URL to open", vim.log.levels.WARN)
    return
  end

  require("astrocore").toggle_term_cmd {
    cmd = "w3m " .. vim.fn.shellescape(url),
    direction = "vertical",
  }
end

local function prompt_w3m()
  vim.ui.input({
    prompt = "Web URL: ",
    default = get_url_under_cursor() or "https://",
  }, function(input)
    if input and input ~= "" then open_w3m(input) end
  end)
end

---@type LazySpec
return {
  {
    "AstroNvim/astrocore",
    optional = true,
    opts = function(_, opts)
      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}
      opts.mappings.n["<Leader>tw"] = { prompt_w3m, desc = "ToggleTerm w3m (enter URL)" }
      opts.mappings.n["<Leader>tW"] = {
        function() open_w3m(get_url_under_cursor()) end,
        desc = "ToggleTerm w3m (open URL under cursor)",
      }
      return opts
    end,
  },
}
