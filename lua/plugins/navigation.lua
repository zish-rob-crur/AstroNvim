return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash 跳转" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash 语法树跳转" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Flash 远程跳转" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Flash 语法树搜索" },
      { "<C-s>", mode = "c", function() require("flash").toggle() end, desc = "Flash 切换搜索" },
    },
  },
  {
    "ThePrimeagen/harpoon",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
    config = function(_, opts) require("harpoon").setup(opts) end,
    keys = {
      { "<Leader>aa", function() require("harpoon.mark").add_file() end, desc = "Harpoon 添加文件" },
      { "<Leader>am", function() require("harpoon.ui").toggle_quick_menu() end, desc = "Harpoon 菜单" },
      { "<Leader>an", function() require("harpoon.ui").nav_next() end, desc = "Harpoon 下一个" },
      { "<Leader>ap", function() require("harpoon.ui").nav_prev() end, desc = "Harpoon 上一个" },
      { "<Leader>1", function() require("harpoon.ui").nav_file(1) end, desc = "Harpoon 文件 1" },
      { "<Leader>2", function() require("harpoon.ui").nav_file(2) end, desc = "Harpoon 文件 2" },
      { "<Leader>3", function() require("harpoon.ui").nav_file(3) end, desc = "Harpoon 文件 3" },
      { "<Leader>4", function() require("harpoon.ui").nav_file(4) end, desc = "Harpoon 文件 4" },
    },
  },
  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}
      opts.mappings.n["<Leader>a"] = { desc = "Harpoon" }
      return opts
    end,
  },
}

