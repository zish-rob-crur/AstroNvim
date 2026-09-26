-- The branch a review is measured against: origin/HEAD if known, else main/master.
local function default_branch()
  local ref = vim.fn.systemlist({ "git", "symbolic-ref", "--short", "refs/remotes/origin/HEAD" })[1]
  if vim.v.shell_error == 0 and ref then return (ref:gsub("^origin/", "")) end
  for _, name in ipairs { "main", "master" } do
    vim.fn.system { "git", "rev-parse", "--verify", "--quiet", name }
    if vim.v.shell_error == 0 then return name end
  end
  return "main"
end

-- IDE-style diagnostics and Git review workflows.

---@type LazySpec
return {
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    keys = {
      { "<Leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Project diagnostics" },
      { "<Leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Buffer diagnostics" },
      { "<Leader>xs", "<cmd>Trouble symbols toggle focus=false<CR>", desc = "Document symbols" },
      { "<Leader>xr", "<cmd>Trouble lsp toggle focus=false win.position=right<CR>", desc = "LSP references/definitions" },
      { "<Leader>xQ", "<cmd>Trouble qflist toggle<CR>", desc = "Quickfix list" },
      { "<Leader>xL", "<cmd>Trouble loclist toggle<CR>", desc = "Location list" },
    },
    opts = {},
  },
  {
    "esmuellert/codediff.nvim",
    cmd = "CodeDiff",
    keys = {
      { "<Leader>gdd", "<cmd>CodeDiff<CR>", desc = "Open Git diff view" },
      {
        "<Leader>gdm",
        function() vim.cmd("CodeDiff " .. default_branch() .. "...") end,
        desc = "Review branch against default branch",
      },
      {
        "<Leader>gdl",
        function() vim.cmd("CodeDiff history " .. default_branch() .. "..HEAD") end,
        desc = "Branch commits since default branch",
      },
      { "<Leader>gdh", "<cmd>CodeDiff history<CR>", desc = "Git file history" },
      { "<Leader>gdH", "<cmd>CodeDiff history %<CR>", desc = "Current file history" },
    },
    opts = {
      diff = {
        layout = "inline",
        filler_text = "",
      },
      explorer = {
        view_mode = "tree",
        width = 30,
      },
      -- Keep review actions local to CodeDiff buffers.
      keymaps = {
        view = {
          quit = { "q", "<Leader>gdc" },
          focus_explorer = "<Leader>gdf",
          toggle_explorer = "<Leader>gdt",
        },
        explorer = { refresh = { "R", "<Leader>gdr" } },
        history = { refresh = { "R", "<Leader>gdr" } },
      },
    },
  },
  {
    "akinsho/git-conflict.nvim",
    version = "*",
    event = "BufReadPost",
    cmd = {
      "GitConflictChooseBoth",
      "GitConflictChooseNone",
      "GitConflictChooseOurs",
      "GitConflictChooseTheirs",
      "GitConflictListQf",
      "GitConflictNextConflict",
      "GitConflictPrevConflict",
      "GitConflictRefresh",
    },
    keys = {
      { "]x", "<cmd>GitConflictNextConflict<CR>", desc = "Next Git conflict" },
      { "[x", "<cmd>GitConflictPrevConflict<CR>", desc = "Previous Git conflict" },
      { "<Leader>gxo", "<cmd>GitConflictChooseOurs<CR>", desc = "Choose ours" },
      { "<Leader>gxt", "<cmd>GitConflictChooseTheirs<CR>", desc = "Choose theirs" },
      { "<Leader>gxb", "<cmd>GitConflictChooseBoth<CR>", desc = "Choose both" },
      { "<Leader>gxn", "<cmd>GitConflictChooseNone<CR>", desc = "Choose none" },
      { "<Leader>gxq", "<cmd>GitConflictListQf<CR>", desc = "List Git conflicts" },
      { "<Leader>gxr", "<cmd>GitConflictRefresh<CR>", desc = "Refresh Git conflicts" },
    },
    opts = {
      default_mappings = false,
      default_commands = true,
      disable_diagnostics = true,
      list_opener = "copen",
    },
  },
  {
    "AstroNvim/astrocore",
    optional = true,
    opts = function(_, opts)
      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}
      opts.mappings.n["<Leader>x"] = { desc = "Problems" }
      opts.mappings.n["<Leader>gd"] = { desc = "Git diff" }
      opts.mappings.n["<Leader>gx"] = { desc = "Git conflict" }
      return opts
    end,
  },
}
