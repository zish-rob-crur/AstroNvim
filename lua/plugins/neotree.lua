return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = function(_, opts)
      opts.filesystem = opts.filesystem or {}
      opts.filesystem.filtered_items = opts.filesystem.filtered_items or {}

      -- 默认显示点文件（如 .env / .github / .zshrc 等）
      opts.filesystem.filtered_items.hide_dotfiles = false

      -- 但保持 .git 目录隐藏，避免噪音
      opts.filesystem.filtered_items.never_show = opts.filesystem.filtered_items.never_show or {}
      if not vim.tbl_contains(opts.filesystem.filtered_items.never_show, ".git") then
        table.insert(opts.filesystem.filtered_items.never_show, ".git")
      end

      return opts
    end,
  },
}
