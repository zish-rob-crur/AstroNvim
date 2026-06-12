return {
  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      opts.options = opts.options or {}
      opts.options.opt = opts.options.opt or {}
      opts.options.g = opts.options.g or {}
      opts.options.opt.wrap = true
      opts.options.opt.linebreak = true
      opts.options.opt.autoread = true
      opts.options.g.loaded_perl_provider = 0
      opts.options.g.loaded_ruby_provider = 0

      opts.autocmds = opts.autocmds or {}
      opts.autocmds.auto_save_changed_files = {
        {
          event = { "BufLeave", "FocusLost", "InsertLeave", "CursorHold", "CursorHoldI" },
          desc = "Auto save changed files",
          callback = function(args)
            local bufnr = args.buf
            local name = vim.api.nvim_buf_get_name(bufnr)
            if name == "" then return end
            if vim.bo[bufnr].buftype ~= "" then return end
            if vim.bo[bufnr].readonly or not vim.bo[bufnr].modifiable then return end
            if not vim.bo[bufnr].modified then return end

            vim.api.nvim_buf_call(bufnr, function() vim.cmd "silent! noautocmd update" end)
          end,
        },
      }
      opts.autocmds.auto_reload_changed_files = {
        {
          event = { "VimEnter", "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" },
          desc = "Auto checktime for files changed on disk",
          callback = function()
            if vim.fn.mode() ~= "c" then vim.cmd "checktime" end
          end,
        },
      }

      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}

      local function copy_current_file_path(relative)
        local path = vim.api.nvim_buf_get_name(0)
        if path == "" then
          vim.notify("Current buffer has no file path", vim.log.levels.WARN)
          return
        end

        path = relative and vim.fn.fnamemodify(path, ":.") or vim.fn.fnamemodify(path, ":p")
        vim.fn.setreg("+", path)
        vim.fn.setreg('"', path)
        vim.notify("Copied: " .. path)
      end

      local function open_current_file_in_browser()
        local path = vim.api.nvim_buf_get_name(0)
        if path == "" then
          vim.notify("Current buffer has no file path", vim.log.levels.WARN)
          return
        end

        vim.fn.jobstart({ "open", vim.fn.fnamemodify(path, ":p") }, { detach = true })
      end

      local noisy_search_excludes = {
        ".git",
        ".venv",
        "node_modules",
        ".pytest_cache",
        ".ruff_cache",
        ".mypy_cache",
        "__pycache__",
      }

      local uv = vim.uv or vim.loop

      local function git_root()
        local root = vim.fs.root(0, ".git")
        return root or uv.cwd() or vim.fn.getcwd()
      end

      local function find_project_files()
        require("snacks").picker.files {
          cwd = git_root(),
          exclude = noisy_search_excludes,
        }
      end

      local function find_all_project_files()
        require("snacks").picker.files {
          cwd = git_root(),
          hidden = true,
          ignored = true,
          exclude = noisy_search_excludes,
        }
      end

      local function command_palette() require("snacks").picker.commands() end

      local function search_project_words()
        require("snacks").picker.grep {
          cwd = git_root(),
          exclude = noisy_search_excludes,
        }
      end

      local function search_all_project_words()
        require("snacks").picker.grep {
          cwd = git_root(),
          hidden = true,
          ignored = true,
          exclude = noisy_search_excludes,
        }
      end

      local function search_word_under_cursor()
        require("snacks").picker.grep_word {
          cwd = git_root(),
          exclude = noisy_search_excludes,
        }
      end

      opts.mappings.n["<Leader>f"] = { desc = "Files" }
      opts.mappings.n["<Leader>s"] = { desc = "Search" }

      opts.mappings.n["<Leader><Space>"] = {
        find_project_files,
        desc = "Find files",
      }
      opts.mappings.n["<C-p>"] = {
        find_project_files,
        desc = "Find files",
      }
      opts.mappings.n["<Leader>p"] = {
        command_palette,
        desc = "Command palette",
      }
      opts.mappings.n["<C-S-f>"] = false
      opts.mappings.n["<C-S-p>"] = false
      opts.mappings.n["<D-p>"] = false
      opts.mappings.n["<D-S-f>"] = false
      opts.mappings.n["<D-S-p>"] = false

      opts.mappings.n["<Leader>ff"] = {
        find_project_files,
        desc = "Find files",
      }
      opts.mappings.n["<Leader>fF"] = {
        find_all_project_files,
        desc = "Find all files",
      }
      opts.mappings.n["<Leader>fb"] = {
        function() require("snacks").picker.buffers() end,
        desc = "Find buffers",
      }
      opts.mappings.n["<Leader>fp"] = false
      opts.mappings.n["<Leader>f/"] = false
      opts.mappings.n["<Leader>fc"] = false
      opts.mappings.n["<Leader>fw"] = false
      opts.mappings.n["<Leader>fW"] = false

      opts.mappings.n["<Leader>sb"] = {
        function() require("snacks").picker.lines() end,
        desc = "Search current buffer",
      }
      opts.mappings.n["<Leader>ss"] = {
        search_project_words,
        desc = "Search text in project",
      }
      opts.mappings.n["<Leader>sS"] = {
        search_all_project_words,
        desc = "Search text in all files",
      }
      opts.mappings.n["<Leader>sw"] = {
        search_word_under_cursor,
        desc = "Search word under cursor",
      }
      opts.mappings.n["<Leader>fg"] = {
        function() require("snacks").picker.git_status() end,
        desc = "Find changed git files",
      }
      opts.mappings.n["<Leader>hp"] = {
        open_current_file_in_browser,
        desc = "Preview current HTML report in browser",
      }
      opts.mappings.n["<Leader>y"] = { desc = "Yank/copy" }
      opts.mappings.n["<Leader>yp"] = {
        function() copy_current_file_path(true) end,
        desc = "Copy relative file path",
      }
      opts.mappings.n["<Leader>yP"] = {
        function() copy_current_file_path(false) end,
        desc = "Copy absolute file path",
      }
    end,
  },
}
