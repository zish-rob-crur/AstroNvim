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
      local snacks = require "snacks"

      local function ensure_dashboard_window(dashboard)
        if dashboard.win and vim.api.nvim_win_is_valid(dashboard.win) then return true end
        if not (dashboard.buf and vim.api.nvim_buf_is_valid(dashboard.buf)) then return false end

        local win = vim.fn.bufwinid(dashboard.buf)
        if win == -1 then return false end

        dashboard.win = win
        return true
      end

      local dashboard = snacks.dashboard
      if type(dashboard) == "table" and type(dashboard.open) == "function" and not dashboard._zish_window_guard then
        local open = dashboard.open
        dashboard.open = function(...)
          local instance = open(...)
          if type(instance) == "table" and type(instance.size) == "function" and not instance._zish_window_guard then
            local size = instance.size
            local update = instance.update

            instance.size = function(self)
              if not ensure_dashboard_window(self) then return self._size or { width = 0, height = 0 } end
              return size(self)
            end

            if type(update) == "function" then
              instance.update = function(self)
                if not ensure_dashboard_window(self) then return end
                return update(self)
              end
            end

            instance._zish_window_guard = true
          end

          return instance
        end
        dashboard._zish_window_guard = true
      end

      snacks.setup(opts)

      local function with_range(command, opts)
        if command.range and command.range > 0 then
          opts.line_start = command.line1
          opts.line_end = command.line2
        end
        return opts
      end

      local function copy_git_url(what)
        return function(command)
          snacks.gitbrowse(with_range(command, {
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

      vim.api.nvim_create_user_command(
        "GitUrlOpen",
        function(command) snacks.gitbrowse(with_range(command, { what = "file" })) end,
        {
          desc = "Open current file GitHub/GitLab URL in browser",
          range = true,
        }
      )
    end,
  },
}
