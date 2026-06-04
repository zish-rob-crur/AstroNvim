return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    init = function()
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          vim.schedule(function()
            local file = vim.api.nvim_buf_get_name(0)
            if require("user.temp_file").is_path(file) then return end

            local cwd = vim.fn.getcwd()
            local command = "Neotree show filesystem right"

            if file ~= "" and vim.startswith(vim.fs.normalize(file), vim.fs.normalize(cwd) .. "/") then
              command = "Neotree show filesystem reveal right"
            end

            pcall(vim.cmd, command)
          end)
        end,
        desc = "Open Neo-tree on the right at startup",
      })
      vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
        callback = function(args) require("user.temp_file").close_sidebars_for_buffer(args.buf) end,
        desc = "Hide sidebars for temporary files",
      })
    end,
    opts = function(_, opts)
      opts.window = opts.window or {}
      opts.window.position = "right"

      opts.filesystem = opts.filesystem or {}
      opts.filesystem.filtered_items = opts.filesystem.filtered_items or {}

      -- Show dotfiles by default, such as .env, .github, and .zshrc.
      opts.filesystem.filtered_items.hide_dotfiles = false

      -- Keep the .git directory hidden to reduce noise.
      opts.filesystem.filtered_items.never_show = opts.filesystem.filtered_items.never_show or {}
      if not vim.tbl_contains(opts.filesystem.filtered_items.never_show, ".git") then
        table.insert(opts.filesystem.filtered_items.never_show, ".git")
      end

      return opts
    end,
  },
}
