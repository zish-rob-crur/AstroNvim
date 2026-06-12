local function copy_path(path, relative)
  if not path or path == "" then
    vim.notify("No path under cursor", vim.log.levels.WARN)
    return
  end

  local copied = relative and vim.fn.fnamemodify(path, ":.") or vim.fn.fnamemodify(path, ":p")
  vim.fn.setreg("+", copied)
  vim.fn.setreg('"', copied)
  vim.notify("Copied: " .. copied)
end

local function copy_node_path(relative)
  return function(state)
    local node = state.tree:get_node()
    copy_path(node and node.path, relative)
  end
end

local function with_neotree_session(method)
  local ok, neotree_session = pcall(require, "user.neotree_session")
  if ok and type(neotree_session[method]) == "function" then pcall(neotree_session[method]) end
end

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    init = function()
      local opening_right_tree = false

      local function neotree_windows()
        local windows = {}
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          local bufnr = vim.api.nvim_win_get_buf(win)
          if vim.bo[bufnr].filetype == "neo-tree" then
            local ok, position = pcall(vim.api.nvim_buf_get_var, bufnr, "neo_tree_position")
            table.insert(windows, { id = win, position = ok and position or nil })
          end
        end
        return windows
      end

      local function open_right_tree(file, cwd)
        local ok_lazy, lazy = pcall(require, "lazy")
        if ok_lazy then pcall(lazy.load, { plugins = { "neo-tree.nvim" } }) end

        local command = "Neotree show filesystem right"

        if file ~= "" and vim.fn.isdirectory(file) == 1 then
          command = "Neotree show filesystem right dir=" .. vim.fn.fnameescape(file)
        elseif file ~= "" and vim.startswith(vim.fs.normalize(file), vim.fs.normalize(cwd) .. "/") then
          command = "Neotree show filesystem reveal right"
        end

        pcall(vim.cmd, command)
      end

      local function restore_right_tree_state()
        vim.defer_fn(function() with_neotree_session "restore" end, 150)
      end

      local function open_dashboard()
        local ok_lazy, lazy = pcall(require, "lazy")
        if ok_lazy then pcall(lazy.load, { plugins = { "snacks.nvim" } }) end

        local ok_snacks, snacks = pcall(require, "snacks")
        if ok_snacks and snacks.dashboard then pcall(snacks.dashboard.open, { buf = 0, win = 0 }) end
      end

      local function schedule_open_right_tree()
        if opening_right_tree then return end
        opening_right_tree = true

        vim.schedule(function()
          local ok, err = xpcall(function()
            local file = vim.api.nvim_buf_get_name(0)
            if require("user.temp_file").is_path(file) then return end

            local cwd = vim.fn.getcwd()
            local all_windows = vim.api.nvim_tabpage_list_wins(0)
            local trees = neotree_windows()
            local starts_with_directory = file ~= "" and vim.fn.isdirectory(file) == 1
            local directory_bufnr = starts_with_directory and vim.api.nvim_get_current_buf() or nil
            local should_open_dashboard = file == "" or starts_with_directory

            if #trees == 1 and trees[1].position == "right" and #all_windows > 1 then
              restore_right_tree_state()
              return
            end

            if #trees > 0 then
              if vim.bo.filetype == "neo-tree" then vim.cmd "enew" end
              pcall(vim.cmd, "Neotree close")
            elseif starts_with_directory then
              vim.cmd "enew"
              if directory_bufnr and vim.api.nvim_buf_is_valid(directory_bufnr) then
                pcall(vim.api.nvim_buf_delete, directory_bufnr, { force = true })
              end
            end

            if should_open_dashboard and vim.bo.filetype ~= "snacks_dashboard" then open_dashboard() end

            open_right_tree(file, cwd)
            restore_right_tree_state()
          end, debug.traceback)

          opening_right_tree = false
          if not ok then error(err) end
        end)
      end

      vim.api.nvim_create_autocmd("VimEnter", {
        callback = schedule_open_right_tree,
        once = true,
        desc = "Open Neo-tree on the right at startup",
      })

      vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function() with_neotree_session "save" end,
        desc = "Save Neo-tree filesystem state",
      })

      vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
        callback = function(args) require("user.temp_file").close_sidebars_for_buffer(args.buf) end,
        desc = "Hide sidebars for temporary files",
      })
    end,
    opts = function(_, opts)
      opts.popup_border_style = "rounded"
      opts.use_popups_for_input = false

      opts.window = opts.window or {}
      opts.window.position = "right"
      opts.window.width = 30

      opts.source_selector = opts.source_selector or {}
      opts.source_selector.winbar = false
      opts.source_selector.statusline = false

      opts.filesystem = opts.filesystem or {}
      opts.filesystem.bind_to_cwd = true
      opts.filesystem.hijack_netrw_behavior = "disabled"
      opts.filesystem.filtered_items = opts.filesystem.filtered_items or {}
      opts.filesystem.commands = opts.filesystem.commands or {}
      opts.filesystem.commands.copy_relative_path = copy_node_path(true)
      opts.filesystem.commands.copy_absolute_path = copy_node_path(false)
      opts.filesystem.window = opts.filesystem.window or {}
      opts.filesystem.window.mappings = opts.filesystem.window.mappings or {}
      opts.filesystem.window.mappings.y = {
        "show_help",
        nowait = false,
        config = { title = "Yank/copy", prefix_key = "y" },
      }
      opts.filesystem.window.mappings.yp = "copy_relative_path"
      opts.filesystem.window.mappings.yP = "copy_absolute_path"

      opts.filesystem.filtered_items.visible = false
      opts.filesystem.filtered_items.hide_dotfiles = true
      opts.filesystem.filtered_items.hide_gitignored = true
      opts.filesystem.filtered_items.hide_hidden = false

      -- Keep the .git directory hidden to reduce noise.
      opts.filesystem.filtered_items.never_show = opts.filesystem.filtered_items.never_show or {}
      if not vim.tbl_contains(opts.filesystem.filtered_items.never_show, ".git") then
        table.insert(opts.filesystem.filtered_items.never_show, ".git")
      end

      return opts
    end,
  },
}
