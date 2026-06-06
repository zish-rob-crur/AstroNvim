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
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewClose",
      "DiffviewFileHistory",
      "DiffviewFocusFiles",
      "DiffviewOpen",
      "DiffviewRefresh",
      "DiffviewToggleFiles",
    },
    keys = {
      { "<Leader>gdd", "<cmd>DiffviewOpen<CR>", desc = "Open Git diff view" },
      { "<Leader>gdc", "<cmd>DiffviewClose<CR>", desc = "Close Git diff view" },
      { "<Leader>gdf", "<cmd>DiffviewFocusFiles<CR>", desc = "Focus diff file panel" },
      { "<Leader>gdt", "<cmd>DiffviewToggleFiles<CR>", desc = "Toggle diff file panel" },
      { "<Leader>gdr", "<cmd>DiffviewRefresh<CR>", desc = "Refresh Git diff view" },
      { "<Leader>gdh", "<cmd>DiffviewFileHistory<CR>", desc = "Git file history" },
      { "<Leader>gdH", "<cmd>DiffviewFileHistory %<CR>", desc = "Current file history" },
    },
    opts = {
      enhanced_diff_hl = true,
      file_panel = {
        listing_style = "tree",
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
