return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.image = { enabled = false }

      local keys = vim.tbl_get(opts, "dashboard", "preset", "keys")
      if type(keys) == "table" then
        for _, key in ipairs(keys) do
          if key.key == "o" and key.action == "<Leader>fo" then key.action = ":lua Snacks.picker.recent()" end
        end
      end

      return opts
    end,
    config = function(_, opts)
      require("snacks").setup(opts)

      local function with_range(command, opts)
        if command.range and command.range > 0 then
          opts.line_start = command.line1
          opts.line_end = command.line2
        end
        return opts
      end

      local function copy_git_url(what)
        return function(command)
          Snacks.gitbrowse(with_range(command, {
            what = what,
            open = function(url)
              vim.fn.setreg("+", url)
              vim.fn.setreg('"', url)
              vim.notify(("Copied git URL: %s"):format(url), vim.log.levels.INFO, { title = "Git URL" })
            end,
          }))
        end
      end

      vim.api.nvim_create_user_command("GitUrlCopy", copy_git_url "file", {
        desc = "Copy current file GitHub/GitLab URL to clipboard",
        range = true,
      })

      vim.api.nvim_create_user_command("GitUrlCopyPermalink", copy_git_url "permalink", {
        desc = "Copy current file GitHub/GitLab permalink to clipboard",
        range = true,
      })

      vim.api.nvim_create_user_command("GitUrlOpen", function(command)
        Snacks.gitbrowse(with_range(command, { what = "file" }))
      end, {
        desc = "Open current file GitHub/GitLab URL in browser",
        range = true,
      })
    end,
  },
}
