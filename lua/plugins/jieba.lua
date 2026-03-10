return {
  {
    "kkew3/jieba.vim",
    branch = "main",
    ft = { "markdown", "text" },
    config = function()
      local group = vim.api.nvim_create_augroup("jieba_vim_markdown_text", { clear = true })

      local function set_jieba_keymaps(bufnr)
        local opts = { buffer = bufnr, silent = true, remap = true }
        local modes = { "n", "x", "o" }
        local maps = {
          w = "<Plug>(Jieba_w)",
          W = "<Plug>(Jieba_W)",
          b = "<Plug>(Jieba_b)",
          B = "<Plug>(Jieba_B)",
          e = "<Plug>(Jieba_e)",
          E = "<Plug>(Jieba_E)",
          ge = "<Plug>(Jieba_ge)",
          gE = "<Plug>(Jieba_gE)",
        }

        for lhs, rhs in pairs(maps) do
          vim.keymap.set(modes, lhs, rhs, opts)
        end
      end

      set_jieba_keymaps(0)

      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = { "markdown", "text" },
        callback = function(ev) set_jieba_keymaps(ev.buf) end,
      })
    end,
  },
}
