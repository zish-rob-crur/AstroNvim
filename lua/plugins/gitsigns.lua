-- Git signs and inline blame annotations.

---@type LazySpec
return {
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true,
      current_line_blame_opts = {
        delay = 300,
        ignore_whitespace = false,
        virt_text = true,
        virt_text_pos = "right_align",
      },
      current_line_blame_formatter = "blame: <author> | <author_time:%Y-%m-%d> | <summary>",
    },
  },
}
