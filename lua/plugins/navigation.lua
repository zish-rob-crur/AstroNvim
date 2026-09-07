local function move_to_split(direction, fallback)
  return function()
    local ok, smart_splits = pcall(require, "smart-splits")
    if ok then
      smart_splits["move_cursor_" .. direction]()
    else
      vim.cmd("wincmd " .. fallback)
    end
  end
end

return {
  {
    "mrjones2014/smart-splits.nvim",
    opts = {
      multiplexer_integration = vim.env.TMUX and "tmux" or nil,
    },
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      modes = {
        search = {
          enabled = true,
        },
      },
    },
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function() require("user.flash_pinyin").jump() end,
        desc = "Flash jump (pinyin initials for Chinese)",
      },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter jump" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Flash remote jump" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Flash Treesitter search" },
      { "<C-s>", mode = "c", function() require("flash").toggle() end, desc = "Toggle Flash search" },
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    optional = true,
    opts = function(_, opts)
      local function flash_in_telescope(prompt_bufnr)
        require("flash").jump({
          pattern = "^",
          label = { after = { 0, 0 } },
          search = {
            mode = "search",
            exclude = {
              function(win)
                return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "TelescopeResults"
              end,
            },
          },
          action = function(match)
            local picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
            picker:set_selection(match.pos[1] - 1)
          end,
        })
      end

      opts.defaults = vim.tbl_deep_extend("force", opts.defaults or {}, {
        mappings = {
          n = { s = flash_in_telescope },
          i = { ["<C-s>"] = flash_in_telescope },
        },
      })

      return opts
    end,
  },
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
    config = function(_, opts) require("harpoon"):setup(opts) end,
    keys = {
      { "<Leader>aa", function() require("harpoon"):list():add() end, desc = "Harpoon add file" },
      {
        "<Leader>am",
        function()
          local harpoon = require "harpoon"
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = "Harpoon menu",
      },
      { "<Leader>an", function() require("harpoon"):list():next() end, desc = "Harpoon next" },
      { "<Leader>ap", function() require("harpoon"):list():prev() end, desc = "Harpoon previous" },
      { "<Leader>1", function() require("harpoon"):list():select(1) end, desc = "Harpoon file 1" },
      { "<Leader>2", function() require("harpoon"):list():select(2) end, desc = "Harpoon file 2" },
      { "<Leader>3", function() require("harpoon"):list():select(3) end, desc = "Harpoon file 3" },
      { "<Leader>4", function() require("harpoon"):list():select(4) end, desc = "Harpoon file 4" },
    },
  },
  {
    "echasnovski/mini.nvim",
    event = "VeryLazy",
    config = function()
      require("mini.ai").setup { n_lines = 500 }
      -- Flash owns `s`, so surround lives under `gs`.
      require("mini.surround").setup {
        mappings = {
          add = "gsa",
          delete = "gsd",
          find = "gsf",
          find_left = "gsF",
          highlight = "gsh",
          replace = "gsr",
          update_n_lines = "gsn",
        },
      }
    end,
  },
  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}
      opts.mappings.n["<Leader>a"] = { desc = "Harpoon" }
      opts.mappings.n["<Leader>w"] = { "<Cmd>w<CR>", desc = "Save" }
      opts.mappings.n["<C-h>"] = { "<Nop>", desc = "Disabled; use <M-h> for split/pane navigation" }
      opts.mappings.n["<C-j>"] = { "<Nop>", desc = "Disabled; use <M-j> for split/pane navigation" }
      opts.mappings.n["<C-k>"] = { "<Nop>", desc = "Disabled; use <M-k> for split/pane navigation" }
      opts.mappings.n["<C-l>"] = { "<Nop>", desc = "Disabled; use <M-l> for split/pane navigation" }
      opts.mappings.n["<C-H>"] = { "<Nop>", desc = "Disabled; use <M-h> for split/pane navigation" }
      opts.mappings.n["<C-J>"] = { "<Nop>", desc = "Disabled; use <M-j> for split/pane navigation" }
      opts.mappings.n["<C-K>"] = { "<Nop>", desc = "Disabled; use <M-k> for split/pane navigation" }
      opts.mappings.n["<C-L>"] = { "<Nop>", desc = "Disabled; use <M-l> for split/pane navigation" }
      opts.mappings.n["<M-h>"] = { move_to_split("left", "h"), desc = "Move to left split" }
      opts.mappings.n["<M-j>"] = { move_to_split("down", "j"), desc = "Move to below split" }
      opts.mappings.n["<M-k>"] = { move_to_split("up", "k"), desc = "Move to above split" }
      opts.mappings.n["<M-l>"] = { move_to_split("right", "l"), desc = "Move to right split" }
      return opts
    end,
  },
}
