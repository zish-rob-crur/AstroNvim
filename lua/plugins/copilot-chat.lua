local function ask_current_buffer()
  vim.ui.input({ prompt = "CopilotChat current buffer: " }, function(input)
    if not input or input == "" then return end
    require("CopilotChat").ask("#buffer:active " .. input)
  end)
end

---@type LazySpec
return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    cmd = {
      "CopilotChat",
      "CopilotChatOpen",
      "CopilotChatClose",
      "CopilotChatToggle",
      "CopilotChatStop",
      "CopilotChatReset",
      "CopilotChatSave",
      "CopilotChatLoad",
      "CopilotChatPrompts",
      "CopilotChatModels",
    },
    dependencies = {
      { "nvim-lua/plenary.nvim", branch = "master" },
    },
    build = "make tiktoken",
    opts = {
      model = "gpt-4.1",
      temperature = 0.1,
      trusted_tools = { "file", "glob", "grep" },
      auto_insert_mode = true,
      window = {
        layout = "vertical",
        width = 0.45,
      },
    },
    keys = {
      { "<Leader>At", "<Cmd>CopilotChatToggle<CR>", desc = "AI chat toggle" },
      { "<Leader>Ao", "<Cmd>CopilotChatOpen<CR>", desc = "AI chat open" },
      { "<Leader>Ac", "<Cmd>CopilotChatReset<CR>", desc = "AI chat clear" },
      { "<Leader>Ap", "<Cmd>CopilotChatPrompts<CR>", desc = "AI prompts" },
      { "<Leader>Am", "<Cmd>CopilotChatModels<CR>", desc = "AI models" },
      { "<Leader>Aa", ask_current_buffer, desc = "AI ask current buffer" },
      { "<Leader>Ae", "<Cmd>CopilotChatExplain<CR>", mode = { "n", "x" }, desc = "AI explain" },
      { "<Leader>Af", "<Cmd>CopilotChatFix<CR>", mode = { "n", "x" }, desc = "AI fix" },
      { "<Leader>Ar", "<Cmd>CopilotChatReview<CR>", mode = { "n", "x" }, desc = "AI review" },
      { "<Leader>As", "<Cmd>CopilotChatStop<CR>", desc = "AI stop" },
    },
  },
  {
    "AstroNvim/astrocore",
    optional = true,
    opts = function(_, opts)
      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}
      opts.mappings.x = opts.mappings.x or {}
      opts.mappings.n["<Leader>A"] = { desc = "AI" }
      opts.mappings.x["<Leader>A"] = { desc = "AI" }
      return opts
    end,
  },
}
